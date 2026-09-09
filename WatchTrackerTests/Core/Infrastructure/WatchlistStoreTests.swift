import Foundation
import Testing
@testable import WatchTracker

@MainActor
@Suite("WatchlistStore", .tags(.service, .async), .timeLimit(.minutes(1)))
struct WatchlistStoreTests {

    @Test func `starts empty and stale`() {
        let store = WatchlistStore()

        #expect(store.cachedItems.isEmpty)
        #expect(store.needsRefresh)
        #expect(store.lastSyncedAt == nil)
    }

    @Test func `replace adopts the list and records when it was true`() {
        let store = WatchlistStore()

        store.replace(with: [TestFixtures.watchItem()])

        #expect(store.cachedItems.count == 1)
        #expect(store.needsRefresh == false)
        #expect(store.lastSyncedAt != nil)
    }

    // MARK: - Across launches

    /// The bug this exists for: launching without a connection used to show an empty Home
    /// under the "add your first title" empty state.
    @Test func `restores the last known list on the next launch`() {
        let archive = InMemoryArchive<WatchlistStore.Snapshot>()
        WatchlistStore(archive: archive).replace(with: [TestFixtures.watchItem(id: 3)])

        let relaunched = WatchlistStore(archive: archive)

        #expect(relaunched.cachedItems.map(\.id) == [3])
        #expect(relaunched.lastSyncedAt != nil)
    }

    /// Restored data is something to show, not a reason to skip the fetch.
    @Test func `a restored list is still stale`() {
        let archive = InMemoryArchive<WatchlistStore.Snapshot>()
        WatchlistStore(archive: archive).replace(with: [TestFixtures.watchItem()])

        #expect(WatchlistStore(archive: archive).needsRefresh)
    }

    @Test func `clear wipes the archive so the next user starts empty`() {
        let archive = InMemoryArchive<WatchlistStore.Snapshot>()
        let store = WatchlistStore(archive: archive)
        store.replace(with: [TestFixtures.watchItem()])

        store.clear()

        #expect(WatchlistStore(archive: archive).cachedItems.isEmpty)
    }

    @Test func `invalidate keeps the list on screen`() {
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem()])

        store.invalidate()

        #expect(store.needsRefresh)
        #expect(store.cachedItems.count == 1)
    }

    // MARK: - Refresh

    @Test func `a failed refresh keeps the previous list and marks it stale`() async {
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem()])
        let service = MockWatchlistService()
        service.fetchWatchlistResult = .failure(APIError.networkError(URLError(.notConnectedToInternet)))

        await store.refresh(using: service)

        #expect(store.cachedItems.count == 1)
        #expect(store.needsRefresh)
    }
}
