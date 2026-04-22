import Foundation
import Combine

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favorites: [AstronomyPicture] = []

    private let key = Constants.UserDefaultsKeys.favorites

    private init() { load() }

    func toggle(_ picture: AstronomyPicture) {
        if isFavorite(picture) {
            favorites.removeAll { $0.id == picture.id }
        } else {
            favorites.insert(picture, at: 0)
            HapticFeedback.notification(.success)
        }
        save()
    }

    func isFavorite(_ picture: AstronomyPicture) -> Bool {
        favorites.contains { $0.id == picture.id }
    }

    func remove(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        favorites.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let items = try? JSONDecoder().decode([AstronomyPicture].self, from: data)
        else { return }
        favorites = items
    }
}
