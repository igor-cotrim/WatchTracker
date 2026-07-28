import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Show notification banner even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle tap — switch to Watching tab and push show detail
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let tmdbId = userInfo["tmdbId"] as? Int {
            DispatchQueue.main.async {
                AppRouter.shared.selectedTab = .watching
                AppRouter.shared.pendingShowId = tmdbId
            }
        }
        completionHandler()
    }
}
