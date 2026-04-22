import XCTest
@testable import SpaceExplorer

final class MarsPhotoTests: XCTestCase {

    func test_jsonDecoding_fullPayload() throws {
        let json = """
        {
            "photos": [{
                "id": 102693,
                "sol": 1000,
                "camera": {
                    "id": 20,
                    "name": "FHAZ",
                    "rover_id": 5,
                    "full_name": "Front Hazard Avoidance Camera"
                },
                "img_src": "https://mars.nasa.gov/photo.jpg",
                "earth_date": "2015-05-30",
                "rover": {
                    "id": 5,
                    "name": "Curiosity",
                    "landing_date": "2012-08-06",
                    "launch_date": "2011-11-26",
                    "status": "active"
                }
            }]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(MarsPhotoResponse.self, from: json)

        XCTAssertEqual(response.photos.count, 1)
        XCTAssertEqual(response.photos[0].id, 102693)
        XCTAssertEqual(response.photos[0].sol, 1000)
        XCTAssertEqual(response.photos[0].camera.name, "FHAZ")
        XCTAssertEqual(response.photos[0].rover.name, "Curiosity")
    }

    func test_marsRover_isActive_curiosityTrue() {
        XCTAssertTrue(MarsRover.curiosity.isActive)
        XCTAssertTrue(MarsRover.perseverance.isActive)
    }

    func test_marsRover_isActive_opportunityFalse() {
        XCTAssertFalse(MarsRover.opportunity.isActive)
        XCTAssertFalse(MarsRover.spirit.isActive)
    }

    func test_marsRover_availableCameras_containsAll() {
        for rover in MarsRover.allCases {
            XCTAssertTrue(rover.availableCameras.contains("All"), "\(rover) missing All camera")
        }
    }

    func test_marsPhoto_imageURL_validURL() {
        let photo = MarsPhoto.fixture()
        XCTAssertNotNil(photo.imageURL)
        XCTAssertEqual(photo.imageURL?.scheme, "https")
    }

    func test_marsPhoto_formattedEarthDate() {
        let photo = MarsPhoto.fixture()
        XCTAssertFalse(photo.formattedEarthDate.isEmpty)
        XCTAssertFalse(photo.formattedEarthDate.contains("-"), "Should use long date format")
    }
}
