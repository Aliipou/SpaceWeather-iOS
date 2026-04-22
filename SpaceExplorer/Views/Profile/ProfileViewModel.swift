import Foundation
import SwiftUI

struct HistoryEntry: Identifiable {
    let id: Int
    let query: String
    let resultType: String
    let searchedAt: Date

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: searchedAt, relativeTo: Date())
    }
}

struct ProfileData: Decodable {
    let id: Int
    let email: String
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let createdAt: String
    let favoritesCount: Int

    enum CodingKeys: String, CodingKey {
        case id, email, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case favoritesCount = "favorites_count"
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: ProfileData?
    @Published var recentHistory: [HistoryEntry] = []
    @Published var historyCount = 0
    @Published var isSyncing = false
    @Published var syncStatus = "Sync local favorites to cloud"

    var memberSince: String {
        guard let dateStr = profile?.createdAt,
              let date = ISO8601DateFormatter().date(from: dateStr) else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    func load() async {
        async let profileTask = fetchProfile()
        async let historyTask = fetchHistory()
        let (p, h) = await (profileTask, historyTask)
        profile = p
        recentHistory = h
        historyCount = h.count
    }

    func updateName(_ name: String) async {
        guard let token = try? await AuthService.shared.validToken() else { return }
        let url = URL(string: Constants.Backend.apiBaseURL + "/profile")!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["display_name": name])
        if let (data, _) = try? await URLSession.shared.data(for: req) {
            profile = try? JSONDecoder().decode(ProfileData.self, from: data)
        }
    }

    func syncFavorites() async {
        isSyncing = true
        syncStatus = "Syncing…"
        defer { isSyncing = false }

        // Load local CoreData favorites and push to backend
        let localFaves = FavoritesStore.shared.allFavorites()
        guard !localFaves.isEmpty else { syncStatus = "Nothing to sync"; return }

        guard let token = try? await AuthService.shared.validToken() else {
            syncStatus = "Sign in to sync"
            return
        }

        let payload = localFaves.map { fav -> [String: Any] in
            var d: [String: Any] = [
                "date": fav.date,
                "title": fav.title,
                "url": fav.url,
                "explanation": fav.explanation,
                "media_type": fav.mediaType,
            ]
            if let hd = fav.hdUrl { d["hd_url"] = hd }
            if let c = fav.copyright { d["copyright"] = c }
            return d
        }

        var req = URLRequest(url: URL(string: Constants.Backend.apiBaseURL + "/favorites/sync")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["favorites": payload])

        if let (data, _) = try? await URLSession.shared.data(for: req),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let added = json["added"] as? Int, let total = json["total"] as? Int {
            syncStatus = "\(total) favorites synced (\(added) new)"
        } else {
            syncStatus = "Sync failed — try again"
        }
    }

    func clearHistory() async {
        guard let token = try? await AuthService.shared.validToken() else { return }
        var req = URLRequest(url: URL(string: Constants.Backend.apiBaseURL + "/history")!)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)
        recentHistory = []
        historyCount = 0
    }

    private func fetchProfile() async -> ProfileData? {
        guard let token = try? await AuthService.shared.validToken() else { return nil }
        var req = URLRequest(url: URL(string: Constants.Backend.apiBaseURL + "/profile")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return try? JSONDecoder().decode(ProfileData.self, from: data)
    }

    private func fetchHistory() async -> [HistoryEntry] {
        guard let token = try? await AuthService.shared.validToken() else { return [] }
        var req = URLRequest(url: URL(string: Constants.Backend.apiBaseURL + "/history?limit=10")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }

        let iso = ISO8601DateFormatter()
        return json.compactMap { item -> HistoryEntry? in
            guard let id = item["id"] as? Int,
                  let query = item["query"] as? String,
                  let type = item["result_type"] as? String,
                  let dateStr = item["searched_at"] as? String,
                  let date = iso.date(from: dateStr) else { return nil }
            return HistoryEntry(id: id, query: query, resultType: type, searchedAt: date)
        }
    }
}
