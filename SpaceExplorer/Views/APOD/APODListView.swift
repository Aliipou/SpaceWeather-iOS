import SwiftUI

struct APODListView: View {
    @StateObject private var viewModel = APODViewModel()
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var network: NetworkMonitor

    @Namespace private var heroNamespace
    @State private var selectedPicture: AstronomyPicture?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                StarFieldView().ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.pictures.isEmpty {
                        loadingGrid
                    } else if let error = viewModel.error, viewModel.pictures.isEmpty {
                        ErrorView(error: error) {
                            await viewModel.refresh()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !viewModel.hasResults && !viewModel.isLoading {
                        EmptyStateView(
                            title: "No Results",
                            message: "Nothing matched your search. Try different keywords.",
                            systemImage: "magnifyingglass"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        pictureGrid
                    }
                }
            }
            .navigationTitle("Space Explorer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search photos, explanations…"
            )
            .background(SpaceTheme.background)
            .task { await viewModel.load() }
        }
        .tint(SpaceTheme.accent)
    }

    // MARK: - Views

    private var pictureGrid: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !network.isConnected {
                    offlineBanner
                }

                ForEach(viewModel.filteredPictures) { picture in
                    NavigationLink {
                        APODDetailView(picture: picture, namespace: heroNamespace)
                            .environmentObject(favorites)
                    } label: {
                        APODCardView(picture: picture, namespace: heroNamespace)
                            .environmentObject(favorites)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .onAppear { HapticFeedback.selection() }
                }
            }
            .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var loadingGrid: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonCard()
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
            Text("Offline — showing cached content")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Picker("Mode", selection: Binding(
                get: { viewModel.loadMode },
                set: { newMode in
                    Task { await viewModel.switchMode(newMode) }
                }
            )) {
                ForEach(APODLoadMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(SpaceTheme.accent)

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .tint(SpaceTheme.accent)
        }
    }
}

// MARK: - Skeleton card

private struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ImageShimmer().frame(height: 220)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(SpaceTheme.glassOverlay).frame(height: 18)
                RoundedRectangle(cornerRadius: 4).fill(SpaceTheme.glassOverlay).frame(width: 200, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(SpaceTheme.glassOverlay).frame(height: 14)
            }
            .padding(14)
        }
        .spaceCard()
        .redacted(reason: .placeholder)
    }
}

#Preview {
    APODListView()
        .environmentObject(FavoritesStore.shared)
        .environmentObject(NetworkMonitor.shared)
}
