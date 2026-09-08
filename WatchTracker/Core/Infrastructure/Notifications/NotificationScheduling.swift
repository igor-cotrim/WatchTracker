import Foundation

protocol NotificationScheduling: Sendable {
    @discardableResult
    func requestAuthorization() async -> Bool
    func scheduleNotifications(for items: [UpcomingItem]) async
    func notifyNewSeason(tmdbId: Int, title: String, seasonNumber: Int) async
    func cancelAllEpisodeNotifications() async
    /// Wipes every notification this account produced, pending and already delivered.
    /// Called when a session ends — see `AuthService.resetLocalUserState()`.
    func removeAllNotifications() async
}

/// Schedules nothing. Used by `AppContainer.preview` so a canvas render never touches
/// `UNUserNotificationCenter` (which would prompt for authorization).
struct PreviewNotificationScheduler: NotificationScheduling {
    func requestAuthorization() async -> Bool { false }
    func scheduleNotifications(for items: [UpcomingItem]) async {}
    func notifyNewSeason(tmdbId: Int, title: String, seasonNumber: Int) async {}
    func cancelAllEpisodeNotifications() async {}
    func removeAllNotifications() async {}
}
