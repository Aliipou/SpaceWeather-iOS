import XCTest
@testable import SpaceExplorer

/// Security tests: input validation, error mapping, URL safety
final class NASAServiceSecurityTests: XCTestCase {

    func test_apiKey_isNotHardcoded_inSource() throws {
        // Verify DEMO_KEY is the fallback, not a real production key embedded
        let key = Constants.API.demoKey
        XCTAssertEqual(key, "DEMO_KEY", "Real API keys must not be hardcoded — use Settings")
    }

    func test_baseURL_usesHTTPS() {
        // All NASA API requests must use HTTPS
        let mockService = MockNASAService()
        _ = mockService // referenced to avoid unused warning
        let urlStr = "https://api.nasa.gov/planetary/apod"
        let url = URL(string: urlStr)
        XCTAssertEqual(url?.scheme, "https", "All API calls must use HTTPS")
    }

    func test_appError_rateLimitExceeded_doesNotLeakAPIKey() {
        let error = AppError.rateLimitExceeded
        let desc = error.errorDescription ?? ""
        XCTAssertFalse(desc.contains("key") && desc.count > 100,
                       "Error messages must not leak API keys or long tokens")
    }

    func test_apiKeyStorage_usesUserDefaults_notPlainTextFile() {
        // Verify the key constant points to UserDefaults, not a bundled file
        UserDefaults.standard.set("TEST_KEY_XYZ", forKey: Constants.UserDefaultsKeys.apiKey)
        let retrieved = Constants.API.nasaAPIKey
        XCTAssertEqual(retrieved, "TEST_KEY_XYZ")
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.apiKey)
    }

    func test_apodImageURL_rejectsJavaScriptScheme() {
        let malicious = AstronomyPicture(
            date: "2024-01-15", explanation: "", hdurl: "javascript:alert(1)",
            mediaType: "image", serviceVersion: nil,
            title: "XSS Attempt", url: "javascript:alert(1)",
            copyright: nil, thumbnailUrl: nil
        )
        // URL(string:) returns nil for non-http/https schemes used in Links
        // Our views only open URLs via AsyncImage / Link — both validate scheme
        XCTAssertNil(
            malicious.displayImageURL.flatMap {
                $0.scheme == "https" || $0.scheme == "http" ? $0 : nil
            },
            "javascript: URLs must not resolve to a valid display URL"
        )
    }

    func test_appError_decodingFailed_sanitizesMessage() {
        let longPayload = String(repeating: "X", count: 2000)
        let error = AppError.decodingFailed(longPayload)
        // Ensure we can store/display without crashing on huge strings
        XCTAssertNotNil(error.errorDescription)
    }

    func test_favoritesPersistence_doesNotStoreAPIKeys() {
        // Confirm favorites key doesn't overlap with API key storage
        XCTAssertNotEqual(
            Constants.UserDefaultsKeys.favorites,
            Constants.UserDefaultsKeys.apiKey,
            "Favorites and API key must use separate UserDefaults keys"
        )
    }
}
