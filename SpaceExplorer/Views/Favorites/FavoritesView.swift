import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @Namespace private var ns
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                StarFieldView().ignoresSafeArea()

                if favorites.favorites.isEmpty {
                    EmptyStateView(
                        title: "No Favorites Yet",
                        message: "Tap the heart on any photo to save it here.",
                        systemImage: "heart.slash"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(favorites.favorites) { picture in
                            NavigationLink {
                                APODDetailView(picture: picture, namespace: ns)
                                    .environmentObject(favorites)
                            } label: {
                                FavoriteRow(picture: picture)
                            }
                            .listRowBackground(SpaceTheme.cardBg)
                            .listRowSeparatorTint(SpaceTheme.divider)
                        }
                        .onDelete(perform: favorites.remove)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SpaceTheme.background)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !favorites.favorites.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showClearAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .alert("Clear All Favorites?", isPresented: $showClearAlert) {
                Button("Clear All", role: .destructive) { favorites.clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}

private struct FavoriteRow: View {
    let picture: AstronomyPicture

    var body: some View {
        HStack(spacing: 14) {
            CachedAsyncImage(url: picture.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ImageShimmer()
            }
            .frame(width: 70, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(picture.title)
                    .font(SpaceTheme.bodyFont())
                    .foregroundStyle(SpaceTheme.textPrimary)
                    .lineLimit(2)
                Text(picture.formattedDate)
                    .font(SpaceTheme.captionFont())
                    .foregroundStyle(SpaceTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}
