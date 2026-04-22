import UIKit

enum HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hapticEnabled) else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hapticEnabled) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hapticEnabled) else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
