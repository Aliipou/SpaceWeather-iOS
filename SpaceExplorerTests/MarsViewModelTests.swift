import XCTest
@testable import SpaceExplorer

@MainActor
final class MarsViewModelTests: XCTestCase {
    private var sut: MarsViewModel!
    private var mockService: MockNASAService!

    override func setUp() {
        super.setUp()
        mockService = MockNASAService()
        sut = MarsViewModel(service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    func test_load_populatesPhotos_onSuccess() async {
        mockService.marsResults = [.fixture(id: 1), .fixture(id: 2), .fixture(id: 3)]

        await sut.load()

        XCTAssertEqual(sut.photos.count, 3)
        XCTAssertNil(sut.error)
    }

    func test_load_setsNoResultsError_whenEmpty() async {
        mockService.marsResults = []

        await sut.load()

        XCTAssertEqual(sut.error, .noResults)
    }

    func test_load_setsNetworkError() async {
        mockService.shouldThrow = .networkUnavailable

        await sut.load()

        XCTAssertTrue(sut.photos.isEmpty)
        XCTAssertEqual(sut.error, .networkUnavailable)
    }

    func test_defaultRover_isCuriosity() {
        XCTAssertEqual(sut.selectedRover, .curiosity)
    }

    func test_defaultQueryMode_isSol() {
        XCTAssertEqual(sut.queryMode, .sol)
    }

    func test_availableCameras_containsAll() {
        XCTAssertTrue(sut.availableCameras.contains("All"))
    }

    func test_refresh_clearsThenReloads() async {
        mockService.marsResults = [.fixture()]
        await sut.load()
        XCTAssertFalse(sut.photos.isEmpty)

        mockService.marsResults = [.fixture(id: 99, sol: 2000)]
        await sut.refresh()

        XCTAssertEqual(sut.photos.count, 1)
        XCTAssertEqual(sut.photos.first?.id, 99)
    }
}
