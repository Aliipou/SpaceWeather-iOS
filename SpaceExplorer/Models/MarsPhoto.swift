import Foundation

struct MarsPhotoResponse: Codable {
    let photos: [MarsPhoto]
}

struct MarsPhoto: Codable, Identifiable, Hashable, Equatable {
    let id: Int
    let sol: Int
    let camera: MarsCamera
    let imgSrc: String
    let earthDate: String
    let rover: MarsRoverInfo

    enum CodingKeys: String, CodingKey {
        case id, sol, camera, rover
        case imgSrc = "img_src"
        case earthDate = "earth_date"
    }

    var imageURL: URL? { URL(string: imgSrc) }

    var formattedEarthDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: earthDate) else { return earthDate }
        formatter.dateStyle = .medium
        return formatter.string(from: d)
    }
}

struct MarsCamera: Codable, Hashable {
    let id: Int
    let name: String
    let roverId: Int
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case roverId = "rover_id"
        case fullName = "full_name"
    }
}

struct MarsRoverInfo: Codable, Hashable {
    let id: Int
    let name: String
    let landingDate: String
    let launchDate: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case landingDate = "landing_date"
        case launchDate = "launch_date"
    }
}

enum MarsRover: String, CaseIterable, Identifiable {
    case curiosity    = "curiosity"
    case opportunity  = "opportunity"
    case spirit       = "spirit"
    case perseverance = "perseverance"

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var isActive: Bool { self == .curiosity || self == .perseverance }

    var availableCameras: [String] {
        switch self {
        case .curiosity, .perseverance:
            return ["All", "FHAZ", "RHAZ", "MAST", "CHEMCAM", "MAHLI", "MARDI", "NAVCAM", "PANCAM"]
        case .opportunity, .spirit:
            return ["All", "FHAZ", "RHAZ", "NAVCAM", "PANCAM", "MINITES", "ENTRY", "MI"]
        }
    }
}
