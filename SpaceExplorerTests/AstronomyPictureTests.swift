import XCTest
@testable import SpaceExplorer

final class AstronomyPictureTests: XCTestCase {

    func test_isImage_trueWhenMediaTypeIsImage() {
        let p = AstronomyPicture.fixture(mediaType: "image")
        XCTAssertTrue(p.isImage)
        XCTAssertFalse(p.isVideo)
    }

    func test_isVideo_trueWhenMediaTypeIsVideo() {
        let p = AstronomyPicture.fixture(mediaType: "video")
        XCTAssertTrue(p.isVideo)
        XCTAssertFalse(p.isImage)
    }

    func test_formattedCopyright_prependsSymbol() {
        let p = AstronomyPicture(
            date: "2024-01-15", explanation: "", hdurl: nil,
            mediaType: "image", serviceVersion: nil,
            title: "Test", url: "https://example.com",
            copyright: "NASA / ESA", thumbnailUrl: nil
        )
        XCTAssertEqual(p.formattedCopyright, "© NASA / ESA")
    }

    func test_formattedCopyright_emptyWhenNil() {
        let p = AstronomyPicture.fixture()
        // fixture has copyright = "NASA"
        XCTAssertFalse(p.formattedCopyright.isEmpty)
    }

    func test_shortExplanation_truncatesLongText() {
        let long = String(repeating: "A", count: 200)
        let p = AstronomyPicture(
            date: "2024-01-15", explanation: long, hdurl: nil,
            mediaType: "image", serviceVersion: nil,
            title: "Test", url: "https://example.com",
            copyright: nil, thumbnailUrl: nil
        )
        XCTAssertTrue(p.shortExplanation.count <= 124) // 120 + "…"
        XCTAssertTrue(p.shortExplanation.hasSuffix("…"))
    }

    func test_shortExplanation_doesNotTruncateShortText() {
        let short = "Short text."
        let p = AstronomyPicture(
            date: "2024-01-15", explanation: short, hdurl: nil,
            mediaType: "image", serviceVersion: nil,
            title: "Test", url: "https://example.com",
            copyright: nil, thumbnailUrl: nil
        )
        XCTAssertEqual(p.shortExplanation, short)
    }

    func test_displayImageURL_prefersHdurl() {
        let p = AstronomyPicture(
            date: "2024-01-15", explanation: "", hdurl: "https://hd.example.com/hd.jpg",
            mediaType: "image", serviceVersion: nil,
            title: "Test", url: "https://sd.example.com/sd.jpg",
            copyright: nil, thumbnailUrl: nil
        )
        XCTAssertEqual(p.displayImageURL?.absoluteString, "https://hd.example.com/hd.jpg")
    }

    func test_displayImageURL_fallsBackToUrl_whenHdurlNil() {
        let p = AstronomyPicture(
            date: "2024-01-15", explanation: "", hdurl: nil,
            mediaType: "image", serviceVersion: nil,
            title: "Test", url: "https://sd.example.com/sd.jpg",
            copyright: nil, thumbnailUrl: nil
        )
        XCTAssertEqual(p.displayImageURL?.absoluteString, "https://sd.example.com/sd.jpg")
    }

    func test_jsonDecoding_snakeCaseKeys() throws {
        let json = """
        {
            "date": "2024-01-15",
            "explanation": "Test explanation",
            "hdurl": "https://example.com/hd.jpg",
            "media_type": "image",
            "service_version": "v1",
            "title": "Test Title",
            "url": "https://example.com/img.jpg"
        }
        """.data(using: .utf8)!

        let picture = try JSONDecoder().decode(AstronomyPicture.self, from: json)

        XCTAssertEqual(picture.title, "Test Title")
        XCTAssertEqual(picture.mediaType, "image")
        XCTAssertEqual(picture.hdurl, "https://example.com/hd.jpg")
    }

    func test_formattedDate_returnsReadableString() {
        let p = AstronomyPicture.fixture(date: "2024-01-15")
        XCTAssertEqual(p.formattedDate, "January 15, 2024")
    }
}
