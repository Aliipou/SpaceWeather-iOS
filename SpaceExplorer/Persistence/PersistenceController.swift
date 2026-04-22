import CoreData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    // MARK: - In-memory store for SwiftUI previews and tests
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext
        for i in 0..<3 {
            let item = FavoriteEntity(context: ctx)
            item.id = "2024-01-\(String(format: "%02d", i + 1))"
            item.title = "Sample Photo \(i + 1)"
            item.date = "2024-01-\(String(format: "%02d", i + 1))"
            item.explanation = "A sample astronomy picture for preview purposes."
            item.url = "https://apod.nasa.gov/apod/image/sample.jpg"
            item.savedAt = Date()
        }
        try? ctx.save()
        return controller
    }()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpaceExplorer")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )

        container.loadPersistentStores { _, error in
            if let error {
                // In production, log to crash reporter (Crashlytics/Sentry)
                fatalError("CoreData store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            ctx.rollback()
        }
    }

    // MARK: - Background context for expensive writes

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
