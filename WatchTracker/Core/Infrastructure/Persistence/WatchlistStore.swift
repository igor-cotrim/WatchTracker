import Foundation

/// Shared in-memory cache for the user's watchlist, and the single owner of when that
/// cache is stale.
///
/// ViewModels read `cachedItems` and hand mutations back through these methods rather
/// than each re-implementing the "refetch, write both properties, get the flag right"
/// dance — three of them used to, and the failure branch was the easy half to get wrong.
@Observable
@MainActor
final class WatchlistStore {
    init() {}

    private(set) var cachedItems: [WatchItem] = []

    /// `true` whenever the watchlist may have been mutated elsewhere, so the next Home
    /// appearance re-fetches. Starts `true` because nothing has been loaded yet.
    private(set) var needsRefresh: Bool = true

    /// Adopts a freshly-fetched list as the new truth.
    func replace(with items: [WatchItem]) {
        cachedItems = items
        needsRefresh = false
    }

    /// Marks the cache stale without discarding it, so screens keep showing the last
    /// known list until the refetch lands.
    func invalidate() {
        needsRefresh = true
    }

    /// Drops everything. Sign-out and account deletion only: the cached list belongs to
    /// the user who just left.
    func clear() {
        cachedItems = []
        needsRefresh = true
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
