import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://api.nasa.gov"
        static let demoKey = "DEMO_KEY"
        // Store your real key in Settings > API Key
        static var nasaAPIKey: String {
            UserDefaults.standard.string(forKey: "nasa_api_key") ?? demoKey
        }
    }

    enum APOD {
        static let defaultCount = 20
        static let maxCount = 100
    }

    enum Mars {
        static let defaultSol = 1000
        static let rovers: [RoverInfo] = [
            RoverInfo(name: "curiosity",   displayName: "Curiosity",   landingDate: "2012-08-06", status: "active"),
            RoverInfo(name: "opportunity", displayName: "Opportunity", landingDate: "2004-01-25", status: "complete"),
            RoverInfo(name: "spirit",      displayName: "Spirit",      landingDate: "2004-01-04", status: "complete"),
            RoverInfo(name: "perseverance",displayName: "Perseverance",landingDate: "2021-02-18", status: "active")
        ]
    }

    enum Cache {
        static let diskCapacity = 500 * 1024 * 1024   // 500 MB
        static let memoryCapacity = 100 * 1024 * 1024  // 100 MB
        static let imageMemoryCapacity = 50 * 1024 * 1024 // 50 MB
    }

    enum Keychain {
        static let apiKeyAccount = "nasa_api_key"
        static let service = "com.spaceexplorer.app"
    }

    enum UserDefaultsKeys {
        static let apiKey = "nasa_api_key"
        static let favorites = "favorite_apod_items"
        static let onboardingComplete = "onboarding_complete"
        static let defaultRover = "default_rover"
        static let hapticEnabled = "haptic_enabled"
    }
}

struct RoverInfo: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let displayName: String
    let landingDate: String
    let status: String
    var isActive: Bool { status == "active" }
}
