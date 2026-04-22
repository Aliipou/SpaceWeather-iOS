import SwiftUI

struct StarFieldView: View {
    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let twinkleDuration: Double
    }

    @State private var twinkle = false
    private let stars: [Star]

    init(count: Int = 120) {
        var rng = SystemRandomNumberGenerator()
        stars = (0..<count).map { i in
            Star(
                id: i,
                x: CGFloat.random(in: 0...1, using: &rng),
                y: CGFloat.random(in: 0...1, using: &rng),
                size: CGFloat.random(in: 1...3, using: &rng),
                opacity: Double.random(in: 0.3...1.0, using: &rng),
                twinkleDuration: Double.random(in: 1.5...4.0, using: &rng)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpaceTheme.background.ignoresSafeArea()

                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                        .opacity(twinkle ? star.opacity : star.opacity * 0.4)
                        .animation(
                            .easeInOut(duration: star.twinkleDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(star.id) * 0.02),
                            value: twinkle
                        )
                }
            }
        }
        .onAppear { twinkle = true }
    }
}

#Preview {
    StarFieldView()
        .frame(width: 400, height: 300)
}
