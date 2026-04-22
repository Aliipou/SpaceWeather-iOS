import Foundation

// MARK: - Protocol

protocol NASAServiceProtocol: Sendable {
    func fetchAPOD(count: Int) async throws -> [AstronomyPicture]
    func fetchAPODByDateRange(startDate: String, endDate: String) async throws -> [AstronomyPicture]
    func fetchMarsPhotos(rover: MarsRover, sol: Int, camera: String?) async throws -> [MarsPhoto]
    func fetchMarsPhotosByDate(rover: MarsRover, earthDate: String, camera: String?) async throws -> [MarsPhoto]
}

// MARK: - Actor-based thread-safe client

actor NASAService: NASAServiceProtocol {
    static let shared = NASAService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: Constants.Cache.memoryCapacity,
            diskCapacity: Constants.Cache.diskCapacity
        )
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func fetchAPOD(count: Int = Constants.APOD.defaultCount) async throws -> [AstronomyPicture] {
        var components = baseComponents(path: "/planetary/apod")
        components.queryItems?.append(contentsOf: [
            URLQueryItem(name: "count", value: "\(count)")
        ])
        return try await fetch([AstronomyPicture].self, from: components)
    }

    func fetchAPODByDateRange(startDate: String, endDate: String) async throws -> [AstronomyPicture] {
        var components = baseComponents(path: "/planetary/apod")
        components.queryItems?.append(contentsOf: [
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date",   value: endDate),
            URLQueryItem(name: "thumbs",     value: "true")
        ])
        return try await fetch([AstronomyPicture].self, from: components)
    }

    func fetchMarsPhotos(rover: MarsRover, sol: Int, camera: String? = nil) async throws -> [MarsPhoto] {
        var components = baseComponents(path: "/mars-photos/api/v1/rovers/\(rover.rawValue)/photos")
        components.queryItems?.append(URLQueryItem(name: "sol", value: "\(sol)"))
        if let camera, camera != "All" {
            components.queryItems?.append(URLQueryItem(name: "camera", value: camera.lowercased()))
        }
        let response = try await fetch(MarsPhotoResponse.self, from: components)
        return response.photos
    }

    func fetchMarsPhotosByDate(rover: MarsRover, earthDate: String, camera: String? = nil) async throws -> [MarsPhoto] {
        var components = baseComponents(path: "/mars-photos/api/v1/rovers/\(rover.rawValue)/photos")
        components.queryItems?.append(URLQueryItem(name: "earth_date", value: earthDate))
        if let camera, camera != "All" {
            components.queryItems?.append(URLQueryItem(name: "camera", value: camera.lowercased()))
        }
        let response = try await fetch(MarsPhotoResponse.self, from: components)
        return response.photos
    }

    // MARK: - Private helpers

    private func baseComponents(path: String) -> URLComponents {
        var c = URLComponents()
        c.scheme = "https"
        c.host = "api.nasa.gov"
        c.path = path
        c.queryItems = [URLQueryItem(name: "api_key", value: Constants.API.nasaAPIKey)]
        return c
    }

    private func fetch<T: Decodable>(_ type: T.Type, from components: URLComponents) async throws -> T {
        guard let url = components.url else { throw AppError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown("Non-HTTP response")
        }

        switch http.statusCode {
        case 200...299: break
        case 429: throw AppError.rateLimitExceeded
        case 403: throw AppError.apiKeyInvalid
        default: throw AppError.invalidResponse(statusCode: http.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decodingFailed(error.localizedDescription)
        }
    }
}
