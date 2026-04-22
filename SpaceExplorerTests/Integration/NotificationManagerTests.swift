import XCTest
import UserNotifications
@testable import SpaceExplorer

@MainActor
final class NotificationManagerTests: XCTestCase {

    func test_notificationCategory_apodUpdate_isCorrectString() {
        XCTAssertEqual(NotificationCategory.apodUpdate, "APOD_UPDATE")
    }

    func test_openAPODTab_notificationName() {
        XCTAssertEqual(Notification.Name.openAPODTab.rawValue, "com.spaceexplorer.openAPODTab")
    }

    func test_notificationManager_shared_isNotNil() {
        XCTAssertNotNil(NotificationManager.shared)
    }

    func test_deepLink_fromNotification_setsAPODTab() {
        var receivedLink: DeepLink?
        let handler = DeepLinkHandler()

        NotificationCenter.default.addObserver(
            forName: .openAPODTab,
            object: nil,
            queue: .main
        ) { _ in
            handler.pendingLink = .apodList
            receivedLink = handler.pendingLink
        }

        NotificationCenter.default.post(name: .openAPODTab, object: nil)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertEqual(receivedLink, .apodList)
    }
}
