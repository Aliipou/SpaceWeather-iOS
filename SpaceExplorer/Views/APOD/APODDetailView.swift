import SwiftUI

struct APODDetailView: View {
    let picture: AstronomyPicture
    let namespace: Namespace.ID

    @EnvironmentObject private var favorites: FavoritesStore
    @State private var showFullScreen = false
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image
                    heroSection

                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        titleSection
                        Divider().background(SpaceTheme.divider)
                        explanationSection
                        if !picture.formattedCopyright.isEmpty {
                            copyrightBadge
                        }
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .background(SpaceTheme.background)
            .ignoresSafeArea(edges: .top)

            // Bottom action bar
            actionBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                FavoriteButton(picture: picture, size: 22)
                    .environmentObject(favorites)
            }
        }
        .sheet(isPresented: $showFullScreen) {
            if let url = picture.displayImageURL {
                FullScreenImageView(url: url, isPresented: $showFullScreen)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = picture.displayImageURL {
                ShareSheet(items: [picture.title, url])
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if picture.isImage, let url = picture.thumbnailURL {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ImageShimmer()
                    }
                    .matchedGeometryEffect(id: "image-\(picture.id)", in: namespace)
                } else {
                    videoPlaceholder
                }
            }
            .frame(height: 340)
            .clipped()
            .onTapGesture {
                if picture.isImage {
                    HapticFeedback.selection()
                    showFullScreen = true
                } else if let url = URL(string: picture.url) {
                    UIApplication.shared.open(url)
                }
            }

            SpaceTheme.heroGradient
                .frame(height: 340)
        }
    }

    private var videoPlaceholder: some View {
        ZStack {
            SpaceTheme.cardBg
            VStack(spacing: 16) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(SpaceTheme.accent)
                Text("Tap to Watch Video")
                    .font(SpaceTheme.bodyFont())
                    .foregroundStyle(SpaceTheme.textSecondary)
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(picture.title)
                .font(SpaceTheme.titleFont(size: 24))
                .foregroundStyle(SpaceTheme.textPrimary)
                .matchedGeometryEffect(id: "title-\(picture.id)", in: namespace)

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                Text(picture.formattedDate)
                    .font(SpaceTheme.captionFont())
            }
            .foregroundStyle(SpaceTheme.accent)
        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("About This Image", systemImage: "info.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpaceTheme.textSecondary)

            Text(picture.explanation)
                .font(SpaceTheme.bodyFont(size: 15))
                .foregroundStyle(SpaceTheme.textPrimary)
                .lineSpacing(6)
        }
    }

    private var copyrightBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "c.circle")
                .font(.system(size: 12))
            Text(picture.formattedCopyright)
                .font(SpaceTheme.captionFont())
        }
        .foregroundStyle(SpaceTheme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(SpaceTheme.glassOverlay)
        .clipShape(Capsule())
    }

    private var actionBar: some View {
        HStack(spacing: 16) {
            if picture.isImage, let url = picture.displayImageURL {
                ActionBarButton(icon: "arrow.up.square", label: "Share") {
                    showShareSheet = true
                }
                ActionBarButton(icon: "arrow.up.left.and.arrow.down.right", label: "Full Screen") {
                    showFullScreen = true
                }
                Link(destination: url) {
                    VStack(spacing: 4) {
                        Image(systemName: "safari")
                            .font(.system(size: 20))
                        Text("Open")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(SpaceTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                }
            } else if let url = URL(string: picture.url) {
                Link(destination: url) {
                    Label("Watch on YouTube", systemImage: "play.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SpaceTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Helpers

private struct ActionBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(SpaceTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
