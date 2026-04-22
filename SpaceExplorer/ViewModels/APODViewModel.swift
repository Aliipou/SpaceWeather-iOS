import Foundation
import Combine

enum APODLoadMode: String, CaseIterable, Identifiable {
    case random = "Random"
    case recent = "Recent"
    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .random: return "shuffle"
        case .recent: return "clock"
        }
    }
}

@MainActor
final class APODViewModel: ObservableObject {
    @Published private(set) var pictures: [AstronomyPicture] = []
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    @Published var loadMode: APODLoadMode = .random
    @Published var searchText = ""

    private let service: NASAServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    var filteredPictures: [AstronomyPicture] {
        guard !searchText.isEmpty else { return pictures }
        return pictures.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.explanation.localizedCaseInsensitiveContains(searchText)
        }
    }

    var hasResults: Bool { !filteredPictures.isEmpty }

    init(service: NASAServiceProtocol = NASAService.shared) {
        self.service = service
        setupSearchDebounce()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            switch loadMode {
            case .random:
                pictures = try await service.fetchAPOD(count: Constants.APOD.defaultCount)
            case .recent:
                let range = DateFormatters.dateRangeStrings(daysBack: 30)
                pictures = try await service.fetchAPODByDateRange(
                    startDate: range.start, endDate: range.end
                )
                pictures = pictures.reversed()
            }
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
    }

    func refresh() async {
        pictures = []
        await load()
    }

    func switchMode(_ mode: APODLoadMode) async {
        guard mode != loadMode else { return }
        loadMode = mode
        await refresh()
    }

    // MARK: - Private

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
