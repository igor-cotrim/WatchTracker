import Foundation

protocol NotificationScheduling: Sendable {
    func scheduleNotifications(for items: [UpcomingItem]) async
    func notifyNewSeason(tmdbId: Int, title: String, seasonNumber: Int) async
}
