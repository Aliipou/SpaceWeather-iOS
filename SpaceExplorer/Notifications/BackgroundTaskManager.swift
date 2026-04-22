import BackgroundTasks
import UIKit

// Register in Info.plist under BGTaskSchedulerPermittedIdentifiers:
//   com.spaceexplorer.apod-refresh

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let taskID = "com.spaceexplorer.apod-refresh"

    private init() {}

    // MARK: - Registration (call once at app launch)

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskID,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self.handleAPODRefresh(task: refreshTask)
        }
    }

    // MARK: - Schedule next fetch

    func scheduleAPODRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 12) // 12 hours

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Scheduling fails in simulator — expected in development
        }
    }

    // MARK: - Handle background fetch

    private func handleAPODRefresh(task: BGAppRefreshTask) {
        scheduleAPODRefresh() // re-schedule for next cycle

        let fetchTask = Task {
            do {
                let pictures = try await NASAService.shared.fetchAPOD(count: 1)
                if let latest = pictures.first {
                    await NotificationManager.shared.showAPODNotification(
                        title: latest.title,
                        date: latest.formattedDate
                    )
                }
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            fetchTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
