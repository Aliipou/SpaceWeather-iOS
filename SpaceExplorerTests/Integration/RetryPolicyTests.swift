import XCTest
@testable import SpaceExplorer

final class RetryPolicyTests: XCTestCase {

    func test_delay_zeroForFirstAttempt() {
        let policy = RetryPolicy.standard
        XCTAssertEqual(policy.delay(for: 0), 0)
    }

    func test_delay_exponentialGrowth() {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 1.0, maxDelay: 16.0, jitter: false)
        let d1 = policy.delay(for: 1) // 1.0
        let d2 = policy.delay(for: 2) // 2.0
        let d3 = policy.delay(for: 3) // 4.0
        XCTAssertEqual(d1, 1.0, accuracy: 0.01)
        XCTAssertEqual(d2, 2.0, accuracy: 0.01)
        XCTAssertEqual(d3, 4.0, accuracy: 0.01)
    }

    func test_delay_capsAtMaxDelay() {
        let policy = RetryPolicy(maxAttempts: 10, baseDelay: 1.0, maxDelay: 5.0, jitter: false)
        let d = policy.delay(for: 8) // would be 128 without cap
        XCTAssertLessThanOrEqual(d, 5.0)
    }

    func test_withRetry_succeedsOnFirstAttempt() async throws {
        var callCount = 0
        let result = try await withRetry(policy: .standard) {
            callCount += 1
            return "ok"
        }
        XCTAssertEqual(result, "ok")
        XCTAssertEqual(callCount, 1)
    }

    func test_withRetry_retriesOnFailure() async throws {
        var callCount = 0
        let result = try await withRetry(
            policy: RetryPolicy(maxAttempts: 3, baseDelay: 0, maxDelay: 0, jitter: false)
        ) {
            callCount += 1
            if callCount < 3 { throw AppError.networkUnavailable }
            return "recovered"
        }
        XCTAssertEqual(result, "recovered")
        XCTAssertEqual(callCount, 3)
    }

    func test_withRetry_throwsAfterMaxAttempts() async {
        var callCount = 0
        do {
            _ = try await withRetry(
                policy: RetryPolicy(maxAttempts: 3, baseDelay: 0, maxDelay: 0, jitter: false)
            ) {
                callCount += 1
                throw AppError.networkUnavailable
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(callCount, 3)
        }
    }

    func test_withRetry_doesNotRetry_whenRetryIfReturnsFalse() async {
        var callCount = 0
        do {
            _ = try await withRetry(
                policy: RetryPolicy(maxAttempts: 3, baseDelay: 0, maxDelay: 0, jitter: false),
                retryIf: { _ in false }
            ) {
                callCount += 1
                throw AppError.apiKeyInvalid
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(callCount, 1, "Should not retry when retryIf returns false")
        }
    }

    func test_appError_isRetryable_correctValues() {
        XCTAssertTrue(AppError.networkUnavailable.isRetryable)
        XCTAssertTrue(AppError.invalidResponse(statusCode: 500).isRetryable)
        XCTAssertFalse(AppError.rateLimitExceeded.isRetryable)
        XCTAssertFalse(AppError.apiKeyInvalid.isRetryable)
        XCTAssertFalse(AppError.decodingFailed("x").isRetryable)
        XCTAssertFalse(AppError.invalidResponse(statusCode: 404).isRetryable)
    }
}
