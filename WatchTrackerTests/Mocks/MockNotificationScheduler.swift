import Foundation
@testable import WatchTracker

final class MockNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _scheduled: [[UpcomingItem]] = []
    private var _newSeasons: [(tmdbId: Int, title: String, seasonNumber: Int)] = []
    private var _authorizationRequestCount = 0
    private var _cancelCount = 0
    private var _removeAllCount = 0
    private var _authorizationResult = true

    // MARK: - Configurable results

    /// What `requestAuthorization()` reports back.
    var authorizationResult: Bool {
        get { lock.withLock { _authorizationResult } }
        set { lock.withLock { _authorizationResult = newValue } }
    }

    // MARK: - Call tracking

    /// One entry per `scheduleNotifications` call.
    var scheduled: [[UpcomingItem]] { lock.withLock { _scheduled } }
    var newSeasons: [(tmdbId: Int, title: String, seasonNumber: Int)] { lock.withLock { _newSeasons } }
    var authorizationRequestCount: Int { lock.withLock { _authorizationRequestCount } }
    var cancelCount: Int { lock.withLock { _cancelCount } }
    var removeAllCount: Int { lock.withLock { _removeAllCount } }

    // MARK: - Protocol conformance

    func requestAuthorization() async -> Bool {
        lock.withLock {
            _authorizationRequestCount += 1
            return _authorizationResult
        }
    }

    func scheduleNotifications(for items: [UpcomingItem]) async {
        lock.withLock { _scheduled.append(items) }
    }

    func notifyNewSeason(tmdbId: Int, title: String, seasonNumber: Int) async {
        lock.withLock { _newSeasons.append((tmdbId: tmdbId, title: title, seasonNumber: seasonNumber)) }
    }

    func cancelAllEpisodeNotifications() async {
        lock.withLock { _cancelCount += 1 }
    }

    func removeAllNotifications() async {
        lock.withLock { _removeAllCount += 1 }
    }
}
