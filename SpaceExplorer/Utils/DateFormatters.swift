import Foundation

enum DateFormatters {
    static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static let displayDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    static func isoString(from date: Date) -> String {
        isoDate.string(from: date)
    }

    static func displayString(from isoString: String) -> String {
        guard let date = isoDate.date(from: isoString) else { return isoString }
        return displayDate.string(from: date)
    }

    static func dateRangeStrings(daysBack: Int) -> (start: String, end: String) {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: end) ?? end
        return (isoString(from: start), isoString(from: end))
    }
}
