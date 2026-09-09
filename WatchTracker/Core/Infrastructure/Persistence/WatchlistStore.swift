import Foundation

/// The watchlist as it was last seen, and the single owner of when that is stale.
///
/// ViewModels read `cachedItems` and hand mutations back through these methods rather
/// than each re-implementing the "refetch, write both properties, get the flag right"
/// dance — three of them used to, and the failure branch was the easy half to get wrong.
///
/// The cache outlives the process. Held only in memory, a launch without a connection
/// showed an empty Home under the "add your first title" empty state, which reads as data
/// loss rather than as a missing connection.
@Observable
@MainActor
final class WatchlistStore {
    /// What is written to disk: the list plus when it was last true.
    nonisolated struct Snapshot: Codable, Sendable {
        let items: [WatchItem]
        let savedAt: Date
    }

    private(set) var cachedItems: [WatchItem] = []

    /// `true` whenever the watchlist may have been mutated elsewhere, so the next Home
    /// appearance re-fetches. Starts `true` because nothing has been loaded yet — a restored
    /// snapshot is a starting point to show, not a reason to skip the fetch.
    private(set) var needsRefresh: Bool = true

    /// When `cachedItems` last came from the backend, across launches. `nil` until the first
    /// successful fetch ever; screens use it to say how old what they are showing is.
    private(set) var lastSyncedAt: Date?

    private let archive: any FileArchiving<Snapshot>

    /// Defaults to the in-memory archive so that only the live container persists anything:
    /// a preview or a test that builds a bare store never writes to the user's disk.
    init(archive: any FileArchiving<Snapshot> = InMemoryArchive()) {
        self.archive = archive
        if let snapshot = archive.load() {
            cachedItems = snapshot.items
            lastSyncedAt = snapshot.savedAt
        }
    }

    /// Adopts a freshly-fetched list as the new truth, and records it for the next launch.
    func replace(with items: [WatchItem]) {
        let now = Date()
        cachedItems = items
        needsRefresh = false
        lastSyncedAt = now
        archive.save(Snapshot(items: items, savedAt: now))
    }

    /// Marks the cache stale without discarding it, so screens keep showing the last
    /// known list until the refetch lands.
    func invalidate() {
        needsRefresh = true
    }

    /// Drops everything, on disk included. Sign-out and account deletion only: the cached
    /// list belongs to the user who just left.
    func clear() {
        cachedItems = []
        needsRefresh = true
        lastSyncedAt = nil
        archive.delete()
    }

    /// Refetches the whole watchlist and adopts it. A failure keeps the previous list on
    /// screen and marks the cache stale, so the next appearance retries.
    func refresh(using service: WatchlistServiceProtocol) async {
        do {
            replace(with: try await service.fetchWatchlist(status: nil, mediaType: nil))
        } catch {
            invalidate()
        }
    }
}
