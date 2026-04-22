import SwiftUI

enum SpaceTheme {
    // MARK: - Colors
    static let background    = Color(red: 0.04, green: 0.04, blue: 0.10)
    static let cardBg        = Color(red: 0.08, green: 0.08, blue: 0.18)
    static let accent        = Color(red: 0.40, green: 0.60, blue: 1.00)
    static let accentGold    = Color(red: 1.00, green: 0.80, blue: 0.30)
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 0.70)
    static let divider       = Color(white: 0.20)
    static let glassOverlay  = Color.white.opacity(0.07)

    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [.clear, background.opacity(0.85), background],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [cardBg, background],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 0.60, green: 0.30, blue: 1.00)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Fonts
    static func titleFont(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func bodyFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func captionFont(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    // MARK: - Card style
    static func cardShadow(radius: CGFloat = 10) -> some ViewModifier {
        SpaceCardModifier(radius: radius)
    }
}

struct SpaceCardModifier: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(SpaceTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: SpaceTheme.accent.opacity(0.15), radius: radius, x: 0, y: 4)
    }
}

// Convenience extension
extension View {
    func spaceCard(radius: CGFloat = 10) -> some View {
        modifier(SpaceCardModifier(radius: radius))
    }
}
