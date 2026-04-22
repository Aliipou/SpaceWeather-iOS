import SwiftUI

struct ErrorView: View {
    let error: AppError
    let retryAction: (() async -> Void)?

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.systemImage)
                .font(.system(size: 54))
                .foregroundStyle(SpaceTheme.accent)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text(error.errorDescription ?? "Something went wrong")
                    .font(SpaceTheme.titleFont(size: 17))
                    .foregroundStyle(SpaceTheme.textPrimary)
                    .multilineTextAlignment(.center)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(SpaceTheme.bodyFont(size: 14))
                        .foregroundStyle(SpaceTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let retryAction {
                Button {
                    HapticFeedback.impact(.medium)
                    isRetrying = true
                    Task {
                        await retryAction()
                        isRetrying = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRetrying {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRetrying ? "Loading…" : "Try Again")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(SpaceTheme.accentGradient)
                    .clipShape(Capsule())
                }
                .disabled(isRetrying)
            }
        }
        .padding(32)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(SpaceTheme.textSecondary)

            Text(title)
                .font(SpaceTheme.titleFont(size: 18))
                .foregroundStyle(SpaceTheme.textPrimary)

            Text(message)
                .font(SpaceTheme.bodyFont())
                .foregroundStyle(SpaceTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
