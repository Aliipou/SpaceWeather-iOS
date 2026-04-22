import SwiftUI

struct MarsRoverView: View {
    @StateObject private var viewModel = MarsViewModel()
    @State private var showFilters = false
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ZStack {
                StarFieldView().ignoresSafeArea()

                VStack(spacing: 0) {
                    roverPicker
                    Divider().background(SpaceTheme.divider)

                    Group {
                        if viewModel.isLoading && viewModel.photos.isEmpty {
                            ProgressView("Contacting rover…")
                                .tint(SpaceTheme.accent)
                                .foregroundStyle(SpaceTheme.textSecondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let error = viewModel.error, viewModel.photos.isEmpty {
                            ErrorView(error: error) { await viewModel.load() }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.photos.isEmpty {
                            EmptyStateView(
                                title: "No Photos",
                                message: "Try a different sol, date, or camera filter.",
                                systemImage: "camera.slash"
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            photoGrid
                        }
                    }
                }
            }
            .background(SpaceTheme.background)
            .navigationTitle("Mars Rover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFilters = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .tint(SpaceTheme.accent)
                }
            }
            .sheet(isPresented: $showFilters) {
                MarsFilterSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .task { await viewModel.load() }
        }
        .tint(SpaceTheme.accent)
    }

    private var roverPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MarsRover.allCases) { rover in
                    Button {
                        HapticFeedback.selection()
                        viewModel.selectedRover = rover
                        Task { await viewModel.refresh() }
                    } label: {
                        Text(rover.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(viewModel.selectedRover == rover ? .white : SpaceTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedRover == rover
                                ? SpaceTheme.accentGradient
                                : LinearGradient(colors: [SpaceTheme.cardBg], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                rover.isActive
                                ? Capsule().stroke(Color.green.opacity(0.6), lineWidth: 1)
                                : nil
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 4)], spacing: 4) {
                ForEach(viewModel.photos) { photo in
                    NavigationLink {
                        MarsPhotoDetailView(photo: photo)
                    } label: {
                        MarsPhotoCell(photo: photo)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
        }
        .refreshable { await viewModel.refresh() }
    }
}

struct MarsPhotoCell: View {
    let photo: MarsPhoto

    var body: some View {
        CachedAsyncImage(url: photo.imageURL) { image in
            image.resizable().aspectRatio(1, contentMode: .fill)
        } placeholder: {
            ImageShimmer().aspectRatio(1, contentMode: .fill)
        }
        .frame(minHeight: 160)
        .clipped()
        .cornerRadius(6)
    }
}

struct MarsFilterSheet: View {
    @ObservedObject var viewModel: MarsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Query By") {
                    Picker("Mode", selection: $viewModel.queryMode) {
                        ForEach(MarsQueryMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if viewModel.queryMode == .sol {
                    Section("Martian Sol") {
                        Stepper("Sol: \(viewModel.sol)", value: $viewModel.sol, in: 0...4000, step: 50)
                    }
                } else {
                    Section("Earth Date") {
                        DatePicker("Date", selection: $viewModel.earthDate, displayedComponents: .date)
                    }
                }

                Section("Camera") {
                    Picker("Camera", selection: $viewModel.selectedCamera) {
                        ForEach(viewModel.availableCameras, id: \.self) { cam in
                            Text(cam).tag(cam)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SpaceTheme.background)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                        Task { await viewModel.refresh() }
                    }
                    .tint(SpaceTheme.accent)
                }
            }
        }
    }
}
