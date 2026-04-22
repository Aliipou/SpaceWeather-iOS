import XCTest
@testable import SpaceExplorer

@MainActor
final class DeepLinkHandlerTests: XCTestCase {
    private var sut: DeepLinkHandler!

    override func setUp() {
        super.setUp()
        sut = DeepLinkHandler()
    }

    private func url(_ str: String) -> URL { URL(string: str)! }

    func test_handle_apodScheme_setsApodList() {
        sut.handle(url: url("spaceexplorer://apod"))
        XCTAssertEqual(sut.pendingLink, .apodList)
    }

    func test_handle_apodWithValidDate_setsApodDate() {
        sut.handle(url: url("spaceexplorer://apod/2024-01-15"))
        XCTAssertEqual(sut.pendingLink, .apodDate("2024-01-15"))
    }

    func test_handle_apodWithInvalidDate_setsApodList() {
        sut.handle(url: url("spaceexplorer://apod/not-a-date"))
        XCTAssertEqual(sut.pendingLink, .apodList)
    }

    func test_handle_marsScheme_setsMarsListByDefault() {
        sut.handle(url: url("spaceexplorer://mars"))
        XCTAssertEqual(sut.pendingLink, .marsList)
    }

    func test_handle_marsWithRover_setsMarsRover() {
        sut.handle(url: url("spaceexplorer://mars/curiosity"))
        XCTAssertEqual(sut.pendingLink, .marsRover(.curiosity))
    }

    func test_handle_marsWithPerseverance() {
        sut.handle(url: url("spaceexplorer://mars/perseverance"))
        XCTAssertEqual(sut.pendingLink, .marsRover(.perseverance))
    }

    func test_handle_favorites() {
        sut.handle(url: url("spaceexplorer://favorites"))
        XCTAssertEqual(sut.pendingLink, .favorites)
    }

    func test_handle_settings() {
        sut.handle(url: url("spaceexplorer://settings"))
        XCTAssertEqual(sut.pendingLink, .settings)
    }

    func test_handle_unknownHost_doesNotSetLink() {
        sut.handle(url: url("spaceexplorer://unknown"))
        XCTAssertNil(sut.pendingLink)
    }

    func test_handle_wrongScheme_doesNotSetLink() {
        sut.handle(url: url("https://api.nasa.gov/apod"))
        XCTAssertNil(sut.pendingLink)
    }

    func test_consume_returnsAndClearsLink() {
        sut.handle(url: url("spaceexplorer://apod"))
        let consumed = sut.consume()
        XCTAssertEqual(consumed, .apodList)
        XCTAssertNil(sut.pendingLink)
    }

    func test_tabIndex_correctMapping() {
        XCTAssertEqual(DeepLink.apodList.tabIndex, 0)
        XCTAssertEqual(DeepLink.apodDate("2024-01-01").tabIndex, 0)
        XCTAssertEqual(DeepLink.marsList.tabIndex, 1)
        XCTAssertEqual(DeepLink.marsRover(.curiosity).tabIndex, 1)
        XCTAssertEqual(DeepLink.favorites.tabIndex, 2)
        XCTAssertEqual(DeepLink.settings.tabIndex, 3)
    }
}
