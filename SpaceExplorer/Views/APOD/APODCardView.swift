import SwiftUI

struct APODCardView: View {
    let picture: AstronomyPicture
    let namespace: Namespace.ID

    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack(alignment: .bottomLeading) {
                thumbnailImage
                    .matchedGeometryEffect(id: "image-\(picture.id)", in: namespace)

                LinearGradient(
                    colors: [.clear, SpaceTheme.background.opacity(0.9)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                if picture.isVideo {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                HStack {
                    Text(picture.formattedDate)
                        .font(SpaceTheme.captionFont())
                        .foregroundStyle(SpaceTheme.textSecondary)
                    Spacer()
                    FavoriteButton(picture: picture, size: 18)
                }
                .padding(10)
            }
            .frame(height: 220)
            .clipped()

            // Text
            VStack(alignment: .leading, spacing: 6) {
                Text(picture.title)
                    .font(SpaceTheme.titleFont(size: 16))
                    .foregroundStyle(SpaceTheme.textPrimary)
                    .lineLimit(2)
                    .matchedGeometryEffect(id: "title-\(picture.id)", in: namespace)

                Text(picture.shortExplanation)
                    .font(SpaceTheme.bodyFont(size: 13))
                    .foregroundStyle(SpaceTheme.textSecondary)
                    .lineLimit(3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .spaceCard()
    }

    @ViewBuilder
    private var thumbnailImage: some View {
        if let url = picture.thumbnailURL {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
            } placeholder: {
                ImageShimmer()
            }
        } else {
            ZStack {
                SpaceTheme.cardBg
                Image(systemName: "film")
                    .font(.system(size: 40))
                    .foregroundStyle(SpaceTheme.textSecondary)
            }
        }
    }
}

// MARK: - Favourite button

struct FavoriteButton: View {
    let picture: AstronomyPicture
    let size: CGFloat

    @EnvironmentObject private var favorites: FavoritesStore
    @State private var isAnimating = false

    var isFav: Bool { favorites.isFavorite(picture) }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
                favorites.toggle(picture)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isAnimating = false
            }
        } label: {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(isFav ? Color.red : SpaceTheme.textSecondary)
                .scaleEffect(isAnimating ? 1.4 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
