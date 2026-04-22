import Foundation
import Security

// MARK: - Models

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct UserProfile: Codable, Equatable {
    let id: Int
    let email: String
    let displayName: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case isActive = "is_active"
    }
}

// MARK: - AuthService

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentUser: UserProfile?
    @Published private(set) var isAuthenticated = false

    private let session: URLSession
    private var accessToken: String? {
        get { Keychain.load(account: Constants.Keychain.accessTokenAccount) }
        set {
            if let v = newValue { Keychain.save(v, account: Constants.Keychain.accessTokenAccount) }
            else { Keychain.delete(account: Constants.Keychain.accessTokenAccount) }
        }
    }
    private var refreshToken: String? {
        get { Keychain.load(account: Constants.Keychain.refreshTokenAccount) }
        set {
            if let v = newValue { Keychain.save(v, account: Constants.Keychain.refreshTokenAccount) }
            else { Keychain.delete(account: Constants.Keychain.refreshTokenAccount) }
        }
    }

    private init() {
        session = URLSession.shared
    }

    // MARK: - Public API

    func register(email: String, password: String, displayName: String? = nil) async throws {
        var body: [String: Any] = ["email": email, "password": password]
        if let name = displayName { body["display_name"] = name }
        let tokens: AuthTokens = try await post("/auth/register", body: body)
        await store(tokens: tokens)
        try await fetchMe()
    }

    func login(email: String, password: String) async throws {
        let tokens: AuthTokens = try await post("/auth/login", body: ["email": email, "password": password])
        await store(tokens: tokens)
        try await fetchMe()
    }

    func logout() async {
        if let token = accessToken {
            try? await post("/auth/logout", body: [:], token: token) as EmptyResponse
        }
        clear()
    }

    func restoreSession() async {
        guard let token = accessToken else { return }
        do {
            let user: UserProfile = try await get("/auth/me", token: token)
            currentUser = user
            isAuthenticated = true
        } catch {
            await refreshIfPossible()
        }
    }

    /// Returns a valid access token, refreshing if needed.
    func validToken() async throws -> String {
        guard let token = accessToken else {
            if await refreshIfPossible() { return accessToken! }
            throw AppError.unauthorized
        }
        return token
    }

    // MARK: - Private

    @discardableResult
    private func refreshIfPossible() async -> Bool {
        guard let rt = refreshToken else { clear(); return false }
        do {
            let tokens: AuthTokens = try await post("/auth/refresh", body: ["refresh_token": rt])
            await store(tokens: tokens)
            try? await fetchMe()
            return true
        } catch {
            clear()
            return false
        }
    }

    private func fetchMe() async throws {
        guard let token = accessToken else { return }
        let user: UserProfile = try await get("/auth/me", token: token)
        currentUser = user
        isAuthenticated = true
    }

    private func store(tokens: AuthTokens) async {
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
    }

    private func clear() {
        accessToken = nil
        refreshToken = nil
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - HTTP helpers

    private func post<T: Decodable>(_ path: String, body: [String: Any], token: String? = nil) async throws -> T {
        var request = URLRequest(url: url(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await execute(request)
    }

    private func get<T: Decodable>(_ path: String, token: String? = nil) async throws -> T {
        var request = URLRequest(url: url(path))
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await execute(request)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AppError.unknown("Non-HTTP") }
        switch http.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        case 401: throw AppError.unauthorized
        case 409: throw AppError.conflict
        default: throw AppError.invalidResponse(statusCode: http.statusCode)
        }
    }

    private func url(_ path: String) -> URL {
        URL(string: Constants.Backend.apiBaseURL + path)!
    }
}

// MARK: - Keychain helpers

private enum Keychain {
    static func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Constants.Keychain.service,
            kSecAttrAccount: account,
            kSecValueData: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Constants.Keychain.service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    static func delete(account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Constants.Keychain.service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Sentinels

private struct EmptyResponse: Decodable {}

extension AppError {
    static let unauthorized = AppError.unknown("unauthorized")
    static let conflict = AppError.unknown("conflict")
}
