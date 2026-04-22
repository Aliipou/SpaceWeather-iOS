import SwiftUI

struct OnboardingView: View {
    @AppStorage(Constants.UserDefaultsKeys.onboardingComplete) private var onboardingComplete = false
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "🌌",
            title: "Welcome to Space Explorer",
            body: "Explore NASA's universe of imagery — from today's Astronomy Picture of the Day to photos from Mars rovers."
        ),
        OnboardingPage(
            icon: "🪐",
            title: "NASA APOD",
            body: "Browse hundreds of stunning space photographs and explanations from NASA's official archive."
        ),
        OnboardingPage(
            icon: "🤖",
            title: "Mars Rovers",
            body: "View raw photos from Curiosity, Perseverance, Opportunity, and Spirit. Filter by sol, date, or camera."
        ),
        OnboardingPage(
            icon: "❤️",
            title: "Save Your Favorites",
            body: "Bookmark any photo to your personal collection. Works offline — your favorites are always available."
        )
    ]

    var body: some View {
        ZStack {
            StarFieldView().ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, p in
                        VStack(spacing: 28) {
                            Text(p.icon)
                                .font(.system(size: 80))
                                .padding(.top, 60)

                            VStack(spacing: 14) {
                                Text(p.title)
                                    .font(SpaceTheme.titleFont(size: 26))
                                    .foregroundStyle(SpaceTheme.textPrimary)
                                    .multilineTextAlignment(.center)

                                Text(p.body)
                                    .font(SpaceTheme.bodyFont(size: 16))
                                    .foregroundStyle(SpaceTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(page == i ? SpaceTheme.accent : SpaceTheme.textSecondary.opacity(0.4))
                            .frame(width: page == i ? 20 : 8, height: 8)
                            .animation(.spring(), value: page)
                    }
                }
                .padding(.bottom, 20)

                // CTA
                Button {
                    HapticFeedback.impact(.medium)
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onboardingComplete = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SpaceTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
}
