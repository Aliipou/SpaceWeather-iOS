import Foundation

enum MarsQueryMode: String, CaseIterable, Identifiable {
    case sol       = "Sol"
    case earthDate = "Earth Date"
    var id: String { rawValue }
}

@MainActor
final class MarsViewModel: ObservableObject {
    @Published private(set) var photos: [MarsPhoto] = []
    @Published private(set) var isLoading = false
    @Published var error: AppError?

    @Published var selectedRover: MarsRover = .curiosity
    @Published var queryMode: MarsQueryMode = .sol
    @Published var sol: Int = Constants.Mars.defaultSol
    @Published var earthDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @Published var selectedCamera = "All"

    private let service: NASAServiceProtocol

    var availableCameras: [String] { selectedRover.availableCameras }

    init(service: NASAServiceProtocol = NASAService.shared) {
        self.service = service
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let cam = selectedCamera == "All" ? nil : selectedCamera
            switch queryMode {
            case .sol:
                photos = try await service.fetchMarsPhotos(
                    rover: selectedRover, sol: sol, camera: cam
                )
            case .earthDate:
                let dateStr = DateFormatters.isoString(from: earthDate)
                photos = try await service.fetchMarsPhotosByDate(
                    rover: selectedRover, earthDate: dateStr, camera: cam
                )
            }
            if photos.isEmpty { error = .noResults }
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
    }

    func refresh() async {
        photos = []
        await load()
    }
}
