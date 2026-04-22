import Foundation

// MARK: - Backend response wrappers

private struct ApodPageResponse: Decodable {
    let items: [AstronomyPicture]
    let nextCursor: String?
    let hasMore: Bool
    let fromCache: Bool
    let cacheHitRatePct: Double

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
        case fromCache = "from_cache"
        case cacheHitRatePct = "cache_hit_rate_pct"
    }
}

private struct MarsPageResponse: Decodable {
    let photos: [MarsPhoto]
    let fromCache: Bool

    enum CodingKeys: String, CodingKey {
        case photos
        case fromCache = "from_cache"
    }
}

struct ApodFeedPage {
    let items: [AstronomyPicture]
    let nextCursor: String?
    let hasMore: Bool
    let fromCache: Bool
    let cacheHitRate: Double
}

// MARK: - BackendService

/// Replaces direct NASA API calls with proxied, authenticated, cached backend calls.
actor BackendService: NASAServiceProtocol {
    static let shared = BackendService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: - NASAServiceProtocol

    func fetchAPOD(count: Int) async throws -> [AstronomyPicture] {
        let token = try await AuthService.shared.validToken()
        return try await get("/apod/random?count=\(count)", token: token)
    }

    func fetchAPODByDateRange(startDate: String, endDate: String) async throws -> [AstronomyPicture] {
        let token = try await AuthService.shared.validToken()
        let page: ApodPageResponse = try await get(
            "/apod/feed?cursor=\(endDate)&page_size=30",
            token: token
        )
        return page.items
    }

    func fetchMarsPhotos(rover: MarsRover, sol: Int, camera: String?) async throws -> [MarsPhoto] {
        let token = try await AuthService.shared.validToken()
        var path = "/mars/\(rover.rawValue)/photos?sol=\(sol)"
        if let camera, camera != "All" { path += "&camera=\(camera.lowercased())" }
        let page: MarsPageResponse = try await get(path, token: token)
        return page.photos
    }

    func fetchMarsPhotosByDate(rover: MarsRover, earthDate: String, camera: String?) async throws -> [MarsPhoto] {
        // Backend doesn't have earth_date endpoint — fall back to NASAService
        return try await NASAService.shared.fetchMarsPhotosByDate(rover: rover, earthDate: earthDate, camera: camera)
    }

    // MARK: - Extended backend-only API

    func fetchAPODFeed(cursor: String? = nil, pageSize: Int = 20) async throws -> ApodFeedPage {
        let token = try await AuthService.shared.validToken()
        var path = "/apod/feed?page_size=\(pageSize)"
        if let cursor { path += "&cursor=\(cursor)" }
        let page: ApodPageResponse = try await get(path, token: token)
        return ApodFeedPage(
            items: page.items,
            nextCursor: page.nextCursor,
            hasMore: page.hasMore,
            fromCache: page.fromCache,
            cacheHitRate: page.cacheHitRatePct
        )
    }

    func fetchTodayAPOD() async throws -> AstronomyPicture {
        let token = try await AuthService.shared.validToken()
        return try await get("/apod/today", token: token)
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String, token: String?) async throws -> T {
        var request = URLRequest(url: url(path))
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AppError.unknown("Non-HTTP response") }
        switch http.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401: throw AppError.unknown("unauthorized")
        case 429: throw AppError.rateLimitExceeded
        default: throw AppError.invalidResponse(statusCode: http.statusCode)
        }
    }

    private func url(_ path: String) -> URL {
        URL(string: Constants.Backend.apiBaseURL + path)!
    }
}
