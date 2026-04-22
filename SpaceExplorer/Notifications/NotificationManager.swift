import UserNotifications
import UIKit

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Schedule daily APOD reminder

    func scheduleDailyAPODReminder(hour: Int = 9, minute: Int = 0) async {
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.dailyAPOD])

        guard authorizationStatus == .authorized else { return }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Today's Space Photo is Ready 🚀"
        content.body = "NASA has published a new Astronomy Picture of the Day. Tap to explore."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = NotificationCategory.apodUpdate

        let request = UNNotificationRequest(
            identifier: NotificationID.dailyAPOD,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Show a picture notification (for background fetch)

    func showAPODNotification(title: String, date: String) async {
        guard authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Space Photo: \(title)"
        content.body = "APOD for \(date) is now available."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.apodUpdate

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.apodFetch)-\(date)",
            content: content,
            trigger: nil   // deliver immediately
        )

        try? await center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Deep-link to APOD tab when notification tapped
        let category = response.notification.request.content.categoryIdentifier
        if category == NotificationCategory.apodUpdate {
            NotificationCenter.default.post(name: .openAPODTab, object: nil)
        }
        completionHandler()
    }
}

// MARK: - Constants

private enum NotificationID {
    static let dailyAPOD  = "com.spaceexplorer.daily-apod"
    static let apodFetch  = "com.spaceexplorer.apod-fetch"
}

enum NotificationCategory {
    static let apodUpdate = "APOD_UPDATE"
}

extension Notification.Name {
    static let openAPODTab = Notification.Name("com.spaceexplorer.openAPODTab")
}
