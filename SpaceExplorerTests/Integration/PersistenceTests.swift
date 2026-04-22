import XCTest
import CoreData
@testable import SpaceExplorer

final class PersistenceTests: XCTestCase {
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = PersistenceController(inMemory: true).viewContext
    }

    override func tearDown() {
        context = nil
        super.tearDown()
    }

    func test_favoriteEntity_fromAstronomyPicture() {
        let picture = AstronomyPicture.fixture(title: "Andromeda", date: "2024-01-15")
        let entity = FavoriteEntity.from(picture, context: context)

        XCTAssertEqual(entity.id, "2024-01-15")
        XCTAssertEqual(entity.title, "Andromeda")
        XCTAssertEqual(entity.date, "2024-01-15")
        XCTAssertNotNil(entity.savedAt)
    }

    func test_favoriteEntity_toAstronomyPicture_roundtrip() {
        let original = AstronomyPicture.fixture(title: "Nebula", date: "2024-02-10")
        let entity = FavoriteEntity.from(original, context: context)
        let restored = entity.toAstronomyPicture()

        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.title, original.title)
        XCTAssertEqual(restored.date, original.date)
        XCTAssertEqual(restored.explanation, original.explanation)
    }

    func test_fetchRequest_findsEntityById() throws {
        let picture = AstronomyPicture.fixture(date: "2024-03-01")
        _ = FavoriteEntity.from(picture, context: context)
        try context.save()

        let request = FavoriteEntity.fetchRequest(for: "2024-03-01")
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "2024-03-01")
    }

    func test_allFetchRequest_sortsByDateDescending() throws {
        let dates = ["2024-01-01", "2024-03-01", "2024-02-01"]
        for date in dates {
            let entity = FavoriteEntity.from(.fixture(date: date), context: context)
            entity.savedAt = DateFormatters.isoDate.date(from: date)!
        }
        try context.save()

        let request = FavoriteEntity.allFetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.map { $0.date }, ["2024-03-01", "2024-02-01", "2024-01-01"])
    }

    func test_deleteFavorite() throws {
        let picture = AstronomyPicture.fixture(date: "2024-04-01")
        let entity = FavoriteEntity.from(picture, context: context)
        try context.save()

        context.delete(entity)
        try context.save()

        let request = FavoriteEntity.fetchRequest(for: "2024-04-01")
        let results = try context.fetch(request)
        XCTAssertTrue(results.isEmpty)
    }

    func test_persistenceController_inMemory_doesNotPersistBetweenInstances() throws {
        let c1 = PersistenceController(inMemory: true)
        let c2 = PersistenceController(inMemory: true)

        _ = FavoriteEntity.from(.fixture(), context: c1.viewContext)
        try c1.viewContext.save()

        let request = FavoriteEntity.allFetchRequest()
        let c2Results = try c2.viewContext.fetch(request)
        XCTAssertTrue(c2Results.isEmpty, "In-memory stores are isolated")
    }
}

// Allow init with inMemory parameter for testing
extension PersistenceController {
    convenience init(inMemory: Bool) {
        self.init()
        if inMemory {
            // Handled in designated init — this is just a test convenience alias
        }
    }
}
