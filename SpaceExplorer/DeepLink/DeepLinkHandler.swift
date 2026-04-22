import Foundation

// MARK: - URL Scheme: spaceexplorer://
// Examples:
//   spaceexplorer://apod              → APOD tab
//   spaceexplorer://apod/2024-01-15   → specific APOD date
//   spaceexplorer://mars              → Mars tab
//   spaceexplorer://mars/curiosity    → Mars tab with Curiosity pre-selected
//   spaceexplorer://favorites         → Favorites tab
//   spaceexplorer://settings          → Settings tab

enum DeepLink: Equatable {
    case apodList
    case apodDate(String)
    case marsList
    case marsRover(MarsRover)
    case favorites
    case settings
}

@MainActor
final class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    @Published var pendingLink: DeepLink?

    private init() {}

    func handle(url: URL) {
        guard url.scheme == "spaceexplorer",
              let host = url.host else { return }

        let path = url.pathComponents.dropFirst() // drop leading "/"

        switch host {
        case "apod":
            if let dateStr = path.first, isValidDate(dateStr) {
                pendingLink = .apodDate(dateStr)
            } else {
                pendingLink = .apodList
            }
        case "mars":
            if let roverStr = path.first,
               let rover = MarsRover(rawValue: roverStr.lowercased()) {
                pendingLink = .marsRover(rover)
            } else {
                pendingLink = .marsList
            }
        case "favorites":
            pendingLink = .favorites
        case "settings":
            pendingLink = .settings
        default:
            break
        }
    }

    func consume() -> DeepLink? {
        defer { pendingLink = nil }
        return pendingLink
    }

    private func isValidDate(_ str: String) -> Bool {
        DateFormatters.isoDate.date(from: str) != nil
    }
}

// MARK: - Tab index mapping

extension DeepLink {
    var tabIndex: Int {
        switch self {
        case .apodList, .apodDate: return 0
        case .marsList, .marsRover: return 1
        case .favorites: return 2
        case .settings: return 3
        }
    }
}
