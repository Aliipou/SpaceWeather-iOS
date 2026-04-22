import Foundation

enum AppError: LocalizedError, Equatable {
    case networkUnavailable
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(String)
    case rateLimitExceeded
    case apiKeyInvalid
    case noResults
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."
        case .invalidURL:
            return "Invalid request URL."
        case .invalidResponse(let code):
            return "Server returned an unexpected response (\(code))."
        case .decodingFailed(let detail):
            return "Failed to parse data: \(detail)"
        case .rateLimitExceeded:
            return "NASA API rate limit exceeded. Add your own API key in Settings."
        case .apiKeyInvalid:
            return "Invalid NASA API key. Check your key in Settings."
        case .noResults:
            return "No results found for your search."
        case .unknown(let msg):
            return msg
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .rateLimitExceeded, .apiKeyInvalid:
            return "Get a free key at api.nasa.gov and add it in Settings."
        case .networkUnavailable:
            return "Check Wi-Fi or cellular data."
        default:
            return "Pull to refresh and try again."
        }
    }

    var systemImage: String {
        switch self {
        case .networkUnavailable: return "wifi.slash"
        case .rateLimitExceeded, .apiKeyInvalid: return "key.slash"
        case .noResults: return "magnifyingglass"
        default: return "exclamationmark.triangle"
        }
    }
}
