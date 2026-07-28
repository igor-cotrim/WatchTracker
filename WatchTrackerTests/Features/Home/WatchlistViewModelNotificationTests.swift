import Testing
import Foundation
@testable import WatchTracker

@MainActor
@Suite("WatchlistViewModel revived seasons", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct WatchlistViewModelNotificationTests {

    private func makeViewModel(
        items: [WatchItem],
        store: WatchlistStore = WatchlistStore()
    ) -> (WatchlistViewModel, MockNotificationScheduler) {
        let service = MockWatchlistService()
        service.fetchWatchlistResult = .success(items)
        let notifications = MockNotificationScheduler()
        let vm = WatchlistViewModel(service: service, store: store, notifications: notifications)
        return (vm, notifications)
    }

    /// `newSeasonNumber` is only set by the backend, so build the item through JSON.
    private func revivedItem(id: Int, tmdbId: Int, title: String, season: Int) -> WatchItem {
        let json = """
        {
            "id": \(id),
            "user_id": "user-1",
            "tmdb_id": \(tmdbId),
            "media_type": "tv",
            "status": "watching",
            "added_at": "2026-01-01T00:00:00Z",
            "title": "\(title)",
            "new_season_number": \(season)
        }
        """
        return try! APIClient.makeDecoder().decode(WatchItem.self, from: Data(json.utf8))
    }

    @Test func `a revived show notifies with its title and season`() async {
        let (vm, notifications) = makeViewModel(items: [
            revivedItem(id: 1, tmdbId: 1399, title: "Game of Thrones", season: 8),
        ])

        await vm.fetchWatchlist()

        #expect(notifications.newSeasons.count == 1)
        #expect(notifications.newSeasons.first?.tmdbId == 1399)
        #expect(notifications.newSeasons.first?.title == "Game of Thrones")
        #expect(notifications.newSeasons.first?.seasonNumber == 8)
    }

    @Test func `items without a new season are not notified`() async {
        let (vm, notifications) = makeViewModel(items: [
            TestFixtures.watchItem(id: 1, tmdbId: 1, mediaType: .tv, status: .watching),
            TestFixtures.watchItem(id: 2, tmdbId: 2, mediaType: .movie, status: .completed),
        ])

        await vm.fetchWatchlist()

        #expect(notifications.newSeasons.isEmpty)
    }

    @Test func `several revived shows each notify once`() async {
        let (vm, notifications) = makeViewModel(items: [
            revivedItem(id: 1, tmdbId: 10, title: "A", season: 2),
            TestFixtures.watchItem(id: 2, tmdbId: 20, mediaType: .tv, status: .watching),
            revivedItem(id: 3, tmdbId: 30, title: "B", season: 5),
        ])

        await vm.fetchWatchlist()

        #expect(notifications.newSeasons.map(\.tmdbId) == [10, 30])
    }

    @Test func `a missing title falls back to an empty string`() async {
        let json = """
        {
            "id": 1, "user_id": "u", "tmdb_id": 5, "media_type": "tv",
            "status": "watching", "added_at": "2026-01-01T00:00:00Z",
            "new_season_number": 3
        }
        """
        let item = try! APIClient.makeDecoder().decode(WatchItem.self, from: Data(json.utf8))
        let (vm, notifications) = makeViewModel(items: [item])

        await vm.fetchWatchlist()

        #expect(notifications.newSeasons.first?.title == "")
    }

    @Test func `a failed fetch notifies nothing`() async {
        let service = MockWatchlistService()
        service.fetchWatchlistResult = .failure(MockError.generic("boom"))
        let notifications = MockNotificationScheduler()
        let vm = WatchlistViewModel(service: service, store: WatchlistStore(), notifications: notifications)

        await vm.fetchWatchlist()

        #expect(notifications.newSeasons.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    @Test func `a skipped fetch notifies nothing`() async {
        // A warm cache short-circuits the fetch entirely.
        let store = WatchlistStore()
        store.cachedItems = [TestFixtures.watchItem()]
        store.needsRefresh = false
        let (vm, notifications) = makeViewModel(
            items: [revivedItem(id: 1, tmdbId: 1, title: "A", season: 2)],
            store: store
        )

        await vm.fetchWatchlist()

        #expect(notifications.newSeasons.isEmpty)
    }
}
