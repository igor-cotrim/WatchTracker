import Foundation
@testable import WatchTracker

final class MockNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _scheduled: [[UpcomingItem]] = []
    private var _newSeasons: [(tmdbId: Int, title: String, seasonNumber: Int)] = []

    /// One entry per `scheduleNotifications` call.
    var scheduled: [[UpcomingItem]] { lock.withLock { _scheduled } }
    var newSeasons: [(tmdbId: Int, title: String, seasonNumber: Int)] { lock.withLock { _newSeasons } }

    func scheduleNotifications(for items: [UpcomingItem]) async {
        lock.withLock { _scheduled.append(items) }
    }

    func notifyNewSeason(tmdbId: Int, title: String, seasonNumber: Int) async {
        lock.withLock { _newSeasons.append((tmdbId: tmdbId, title: title, seasonNumber: seasonNumber)) }
    }
}
