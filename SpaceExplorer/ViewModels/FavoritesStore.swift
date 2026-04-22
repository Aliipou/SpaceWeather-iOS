import CoreData
import Combine

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favorites: [AstronomyPicture] = []

    private let context: NSManagedObjectContext

    private init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        loadFromCoreData()
        observeContextChanges()
    }

    // MARK: - Public API

    func toggle(_ picture: AstronomyPicture) {
        if isFavorite(picture) {
            delete(picture)
        } else {
            insert(picture)
            HapticFeedback.notification(.success)
        }
    }

    func isFavorite(_ picture: AstronomyPicture) -> Bool {
        favorites.contains { $0.id == picture.id }
    }

    func remove(at offsets: IndexSet) {
        let toDelete = offsets.map { favorites[$0] }
        toDelete.forEach { delete($0) }
    }

    func clearAll() {
        let request = FavoriteEntity.allFetchRequest()
        guard let entities = try? context.fetch(request) else { return }
        entities.forEach { context.delete($0) }
        PersistenceController.shared.save()
    }

    // MARK: - Private CoreData

    private func insert(_ picture: AstronomyPicture) {
        _ = FavoriteEntity.from(picture, context: context)
        PersistenceController.shared.save()
    }

    private func delete(_ picture: AstronomyPicture) {
        let request = FavoriteEntity.fetchRequest(for: picture.id)
        guard let entity = try? context.fetch(request).first else { return }
        context.delete(entity)
        PersistenceController.shared.save()
    }

    private func loadFromCoreData() {
        let request = FavoriteEntity.allFetchRequest()
        favorites = (try? context.fetch(request))?.map { $0.toAstronomyPicture() } ?? []
    }

    private func observeContextChanges() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] _ in
            self?.loadFromCoreData()
        }
    }
}

// MARK: - Preview support

extension FavoritesStore {
    static let preview: FavoritesStore = FavoritesStore(
        context: PersistenceController.preview.viewContext
    )
}
