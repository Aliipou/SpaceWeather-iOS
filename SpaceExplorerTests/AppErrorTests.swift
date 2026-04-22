import XCTest
@testable import SpaceExplorer

final class AppErrorTests: XCTestCase {

    func test_errorDescription_networkUnavailable() {
        let error = AppError.networkUnavailable
        XCTAssertTrue(error.errorDescription?.contains("No internet") == true)
    }

    func test_errorDescription_rateLimitExceeded() {
        let error = AppError.rateLimitExceeded
        XCTAssertTrue(error.errorDescription?.contains("rate limit") == true)
    }

    func test_errorDescription_invalidResponse_includesStatusCode() {
        let error = AppError.invalidResponse(statusCode: 503)
        XCTAssertTrue(error.errorDescription?.contains("503") == true)
    }

    func test_recoverySuggestion_rateLimitExceeded_mentionsSettings() {
        let error = AppError.rateLimitExceeded
        XCTAssertTrue(error.recoverySuggestion?.contains("Settings") == true)
    }

    func test_systemImage_networkUnavailable() {
        XCTAssertEqual(AppError.networkUnavailable.systemImage, "wifi.slash")
    }

    func test_systemImage_rateLimit() {
        XCTAssertEqual(AppError.rateLimitExceeded.systemImage, "key.slash")
    }

    func test_systemImage_noResults() {
        XCTAssertEqual(AppError.noResults.systemImage, "magnifyingglass")
    }

    func test_equality() {
        XCTAssertEqual(AppError.networkUnavailable, AppError.networkUnavailable)
        XCTAssertNotEqual(AppError.networkUnavailable, AppError.rateLimitExceeded)
        XCTAssertEqual(AppError.invalidResponse(statusCode: 404), AppError.invalidResponse(statusCode: 404))
        XCTAssertNotEqual(AppError.invalidResponse(statusCode: 404), AppError.invalidResponse(statusCode: 500))
    }
}
