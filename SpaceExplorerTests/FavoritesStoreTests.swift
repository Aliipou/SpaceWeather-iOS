import XCTest
@testable import SpaceExplorer

@MainActor
final class FavoritesStoreTests: XCTestCase {
    private var sut: FavoritesStore!
    private let testKey = "test_favorites_\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        // Use an isolated UserDefaults domain per test run
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.favorites)
        sut = FavoritesStore.shared
        sut.clearAll()
    }

    func test_toggle_addsFavorite() {
        let picture = AstronomyPicture.fixture()

        sut.toggle(picture)

        XCTAssertTrue(sut.isFavorite(picture))
        XCTAssertEqual(sut.favorites.count, 1)
    }

    func test_toggle_removesFavorite_whenAlreadyFavorited() {
        let picture = AstronomyPicture.fixture()
        sut.toggle(picture)
        XCTAssertTrue(sut.isFavorite(picture))

        sut.toggle(picture)

        XCTAssertFalse(sut.isFavorite(picture))
        XCTAssertTrue(sut.favorites.isEmpty)
    }

    func test_isFavorite_returnsFalse_whenNotFavorited() {
        let picture = AstronomyPicture.fixture()
        XCTAssertFalse(sut.isFavorite(picture))
    }

    func test_remove_atOffsets() {
        let p1 = AstronomyPicture.fixture(date: "2024-01-01", title: "First")
        let p2 = AstronomyPicture.fixture(date: "2024-01-02", title: "Second")
        sut.toggle(p1)
        sut.toggle(p2)
        XCTAssertEqual(sut.favorites.count, 2)

        sut.remove(at: IndexSet(integer: 0))

        XCTAssertEqual(sut.favorites.count, 1)
    }

    func test_clearAll_removesEverything() {
        sut.toggle(.fixture(date: "2024-01-01", title: "A"))
        sut.toggle(.fixture(date: "2024-01-02", title: "B"))

        sut.clearAll()

        XCTAssertTrue(sut.favorites.isEmpty)
    }

    func test_addingMultipleFavorites_maintainsOrder() {
        let oldest = AstronomyPicture.fixture(date: "2024-01-01", title: "Old")
        let newest = AstronomyPicture.fixture(date: "2024-01-10", title: "New")

        sut.toggle(oldest)
        sut.toggle(newest)

        // Newest added should be first (insert at 0)
        XCTAssertEqual(sut.favorites.first?.title, "New")
    }
}
