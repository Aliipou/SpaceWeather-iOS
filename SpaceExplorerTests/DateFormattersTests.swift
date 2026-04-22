import XCTest
@testable import SpaceExplorer

final class DateFormattersTests: XCTestCase {

    func test_isoString_roundtrips() {
        let date = Date(timeIntervalSince1970: 1_705_276_800) // 2024-01-15
        let str = DateFormatters.isoString(from: date)
        XCTAssertEqual(str, "2024-01-15")
    }

    func test_displayString_formatsReadably() {
        let result = DateFormatters.displayString(from: "2024-01-15")
        XCTAssertEqual(result, "January 15, 2024")
    }

    func test_displayString_returnsRaw_whenInvalidInput() {
        let invalid = "not-a-date"
        XCTAssertEqual(DateFormatters.displayString(from: invalid), invalid)
    }

    func test_dateRangeStrings_startBeforeEnd() {
        let range = DateFormatters.dateRangeStrings(daysBack: 30)
        let start = DateFormatters.isoDate.date(from: range.start)!
        let end = DateFormatters.isoDate.date(from: range.end)!
        XCTAssertLessThan(start, end)
    }

    func test_dateRangeStrings_correctInterval() {
        let range = DateFormatters.dateRangeStrings(daysBack: 7)
        let start = DateFormatters.isoDate.date(from: range.start)!
        let end = DateFormatters.isoDate.date(from: range.end)!
        let diff = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        XCTAssertEqual(diff, 7)
    }
}
