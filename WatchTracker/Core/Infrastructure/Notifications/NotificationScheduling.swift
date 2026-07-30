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
