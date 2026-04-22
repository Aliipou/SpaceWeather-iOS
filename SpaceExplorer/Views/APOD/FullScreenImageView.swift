import SwiftUI

struct FullScreenImageView: View {
    let url: URL
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showChrome = true

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, minScale), maxScale)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if scale < minScale {
                                            withAnimation(.spring()) { scale = minScale }
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        if scale <= minScale {
                                            withAnimation(.spring()) { offset = .zero }
                                        }
                                        lastOffset = offset
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                scale = scale > 1.5 ? 1.0 : 2.5
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showChrome.toggle()
                            }
                        }
                case .empty, .failure:
                    ProgressView().tint(SpaceTheme.accent)
                @unknown default:
                    EmptyView()
                }
            }

            if showChrome {
                Button {
                    HapticFeedback.selection()
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.black.opacity(0.5))
                }
                .padding()
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
    }
}
