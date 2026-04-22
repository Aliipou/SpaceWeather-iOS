import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                content(image)
            case .failure:
                placeholder()
            case .empty:
                placeholder()
            @unknown default:
                placeholder()
            }
        }
    }
}

// MARK: - Convenience shimmer placeholder

struct ImageShimmer: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            SpaceTheme.cardBg,
                            SpaceTheme.cardBg.opacity(0.4),
                            SpaceTheme.cardBg
                        ],
                        startPoint: UnitPoint(x: phase, y: 0),
                        endPoint: UnitPoint(x: phase + 1, y: 0)
                    )
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }
}
