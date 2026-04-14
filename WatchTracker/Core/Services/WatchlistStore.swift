import Foundation

/// Shared in-memory cache for the user's watchlist.
/// ViewModels read from and write to this store instead of hitting the network on every appearance.
@Observable
final class WatchlistStore {
    static let shared = WatchlistStore()
    private init() {}

    var cachedItems: [WatchItem] = []
    /// Set to `true` whenever the watchlist is mutated (add/remove) so the next Home appearance re-fetches.
    var needsRefresh: Bool = true
}
