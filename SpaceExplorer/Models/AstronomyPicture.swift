import Foundation

struct AstronomyPicture: Codable, Identifiable, Hashable, Equatable {
    var id: String { date }

    let date: String
    let explanation: String
    let hdurl: String?
    let mediaType: String
    let serviceVersion: String?
    let title: String
    let url: String
    let copyright: String?
    let thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case date, explanation, hdurl, title, url, copyright
        case mediaType = "media_type"
        case serviceVersion = "service_version"
        case thumbnailUrl = "thumbnail_url"
    }

    var isImage: Bool { mediaType == "image" }
    var isVideo: Bool { mediaType == "video" }

    var formattedCopyright: String {
        guard let copyright else { return "" }
        let cleaned = copyright.trimmingCharacters(in: .whitespacesAndNewlines)
        return "© \(cleaned)"
    }

    var displayImageURL: URL? {
        let raw = hdurl ?? url
        return URL(string: raw)
    }

    var thumbnailURL: URL? {
        if let thumb = thumbnailUrl { return URL(string: thumb) }
        return isImage ? URL(string: url) : nil
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: date) else { return self.date }
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var shortExplanation: String {
        let maxLength = 120
        guard explanation.count > maxLength else { return explanation }
        return String(explanation.prefix(maxLength)) + "…"
    }
}
