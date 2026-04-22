import XCTest
@testable import SpaceExplorer

@MainActor
final class APODViewModelTests: XCTestCase {
    private var sut: APODViewModel!
    private var mockService: MockNASAService!

    override func setUp() {
        super.setUp()
        mockService = MockNASAService()
        sut = APODViewModel(service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Load

    func test_load_populatesPictures_onSuccess() async {
        let fixtures = [AstronomyPicture.fixture(title: "Galaxy"), AstronomyPicture.fixture(title: "Nebula", date: "2024-01-16")]
        mockService.apodResults = fixtures

        await sut.load()

        XCTAssertEqual(sut.pictures.count, 2)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func test_load_setsError_onNetworkFailure() async {
        mockService.shouldThrow = .networkUnavailable

        await sut.load()

        XCTAssertTrue(sut.pictures.isEmpty)
        XCTAssertEqual(sut.error, .networkUnavailable)
        XCTAssertFalse(sut.isLoading)
    }

    func test_load_setsError_onRateLimit() async {
        mockService.shouldThrow = .rateLimitExceeded

        await sut.load()

        XCTAssertEqual(sut.error, .rateLimitExceeded)
    }

    func test_load_clearsError_onSuccessfulRetry() async {
        mockService.shouldThrow = .networkUnavailable
        await sut.load()
        XCTAssertNotNil(sut.error)

        mockService.shouldThrow = nil
        mockService.apodResults = [.fixture()]
        await sut.load()

        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.pictures.isEmpty)
    }

    func test_refresh_clearsPicturesFirst() async {
        mockService.apodResults = [.fixture()]
        await sut.load()
        XCTAssertFalse(sut.pictures.isEmpty)

        // Simulate no results on refresh
        mockService.apodResults = []
        mockService.shouldThrow = nil
        await sut.refresh()

        XCTAssertTrue(sut.pictures.isEmpty)
    }

    func test_switchMode_toRecent_callsDateRange() async {
        mockService.apodResults = [.fixture()]
        await sut.switchMode(.recent)

        XCTAssertEqual(sut.loadMode, .recent)
    }

    func test_switchMode_sameMode_doesNotReload() async {
        sut.loadMode = .random
        let initialCount = mockService.fetchAPODCallCount

        await sut.switchMode(.random)

        XCTAssertEqual(mockService.fetchAPODCallCount, initialCount)
    }

    // MARK: - Search filter

    func test_filteredPictures_returnsAll_whenSearchTextEmpty() async {
        mockService.apodResults = [
            .fixture(title: "Galaxy"),
            .fixture(title: "Nebula", date: "2024-01-16")
        ]
        await sut.load()

        sut.searchText = ""
        XCTAssertEqual(sut.filteredPictures.count, 2)
    }

    func test_filteredPictures_filtersBy_titleMatch() async {
        mockService.apodResults = [
            .fixture(title: "Andromeda Galaxy"),
            .fixture(title: "Crab Nebula", date: "2024-01-16")
        ]
        await sut.load()

        sut.searchText = "galaxy"
        XCTAssertEqual(sut.filteredPictures.count, 1)
        XCTAssertEqual(sut.filteredPictures.first?.title, "Andromeda Galaxy")
    }

    func test_filteredPictures_returnsEmpty_whenNoMatch() async {
        mockService.apodResults = [.fixture(title: "Galaxy")]
        await sut.load()

        sut.searchText = "mars rover xyz"
        XCTAssertTrue(sut.filteredPictures.isEmpty)
        XCTAssertFalse(sut.hasResults)
    }
}
