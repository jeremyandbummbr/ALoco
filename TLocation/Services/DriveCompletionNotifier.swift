import Foundation
import UserNotifications

enum DriveCompletionNotifier {
    private static let foregroundDelegate = DriveNotificationDelegate()

    static func configure() {
        UNUserNotificationCenter.current().delegate = foregroundDelegate
    }

    static func requestPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    static func postDone() {
        let content = UNMutableNotificationContent()
        content.title = "Drive done."
        content.body = "Your simulated drive reached its destination. Tap Stop in ALOCO to return to your real location."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

private final class DriveNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
