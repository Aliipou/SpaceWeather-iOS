import Foundation

// MARK: - Exponential backoff retry for transient failures

struct RetryPolicy {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let jitter: Bool

    static let standard = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 16.0, jitter: true)
    static let aggressive = RetryPolicy(maxAttempts: 5, baseDelay: 0.5, maxDelay: 30.0, jitter: true)
    static let none = RetryPolicy(maxAttempts: 1, baseDelay: 0, maxDelay: 0, jitter: false)

    func delay(for attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        let exponential = min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
        guard jitter else { return exponential }
        let jitterAmount = exponential * 0.3
        return exponential + Double.random(in: -jitterAmount...jitterAmount)
    }
}

// MARK: - Retry wrapper

func withRetry<T>(
    policy: RetryPolicy = .standard,
    retryIf: (Error) -> Bool = { _ in true },
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 0..<policy.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            guard retryIf(error), attempt < policy.maxAttempts - 1 else { throw error }
            let delay = policy.delay(for: attempt + 1)
            if delay > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? AppError.unknown("Retry exhausted")
}

// MARK: - AppError retry eligibility

extension AppError {
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable: return true
        case .invalidResponse(let code): return code >= 500
        case .rateLimitExceeded: return false
        case .apiKeyInvalid: return false
        case .decodingFailed: return false
        case .noResults: return false
        default: return true
        }
    }
}
