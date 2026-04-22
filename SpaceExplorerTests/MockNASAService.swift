import Foundation
@testable import SpaceExplorer

final class MockNASAService: NASAServiceProtocol, @unchecked Sendable {
    var shouldThrow: AppError?
    var apodResults: [AstronomyPicture] = []
    var marsResults: [MarsPhoto] = []

    var fetchAPODCallCount = 0
    var fetchMarsCallCount = 0

    func fetchAPOD(count: Int) async throws -> [AstronomyPicture] {
        fetchAPODCallCount += 1
        if let error = shouldThrow { throw error }
        return apodResults
    }

    func fetchAPODByDateRange(startDate: String, endDate: String) async throws -> [AstronomyPicture] {
        if let error = shouldThrow { throw error }
        return apodResults
    }

    func fetchMarsPhotos(rover: MarsRover, sol: Int, camera: String?) async throws -> [MarsPhoto] {
        fetchMarsCallCount += 1
        if let error = shouldThrow { throw error }
        return marsResults
    }

    func fetchMarsPhotosByDate(rover: MarsRover, earthDate: String, camera: String?) async throws -> [MarsPhoto] {
        if let error = shouldThrow { throw error }
        return marsResults
    }
}

// MARK: - Fixtures

extension AstronomyPicture {
    static func fixture(
        date: String = "2024-01-15",
        title: String = "Andromeda Galaxy",
        mediaType: String = "image",
        url: String = "https://apod.nasa.gov/apod/image/2401/andromeda.jpg"
    ) -> AstronomyPicture {
        AstronomyPicture(
            date: date,
            explanation: "A breathtaking view of our nearest galactic neighbor.",
            hdurl: url,
            mediaType: mediaType,
            serviceVersion: "v1",
            title: title,
            url: url,
            copyright: "NASA",
            thumbnailUrl: nil
        )
    }
}

extension MarsPhoto {
    static func fixture(id: Int = 1, sol: Int = 1000) -> MarsPhoto {
        MarsPhoto(
            id: id,
            sol: sol,
            camera: MarsCamera(id: 1, name: "FHAZ", roverId: 5, fullName: "Front Hazard Avoidance Camera"),
            imgSrc: "https://mars.nasa.gov/msl-raw-images/proj/msl/redops/ods/surface/sol/01000/opgs/edr/fcam/FLB_486265257EDR_F0481570FHAZ00323M_.JPG",
            earthDate: "2015-05-30",
            rover: MarsRoverInfo(id: 5, name: "Curiosity", landingDate: "2012-08-06", launchDate: "2011-11-26", status: "active")
        )
    }
}
