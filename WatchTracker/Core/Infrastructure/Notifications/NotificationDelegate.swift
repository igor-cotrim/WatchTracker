import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
        super.init()
    }

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
            DispatchQueue.main.async { [router] in
                router.selectedTab = .watching
                router.pendingShowId = tmdbId
            }
        }
        completionHandler()
    }
}
