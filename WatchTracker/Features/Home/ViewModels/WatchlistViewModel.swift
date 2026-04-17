import Foundation

enum MediaFilter: String, CaseIterable, Identifiable {
    case all
    case movie
    case tv
    case anime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:   Strings.MediaFilter.all
        case .movie: Strings.MediaFilter.movies
        case .tv:    Strings.MediaFilter.tv
        case .anime: Strings.MediaFilter.anime
        }
    }
}

@Observable
@MainActor
final class WatchlistViewModel {
    var allItems: [WatchItem] = []
    var isLoading = false
    var selectedFilter: MediaFilter = .all
    var selectedStatus: WatchlistStatus = .watching
    var errorMessage: String?

    private let service: any WatchlistServiceProtocol
    private let store: WatchlistStore

    init(
        service: any WatchlistServiceProtocol = WatchlistService(),
        store: WatchlistStore = .shared
    ) {
        self.service = service
        self.store = store
        allItems = store.cachedItems
    }

    /// Returns items filtered by the current status pill and the given media filter.
    func items(for filter: MediaFilter) -> [WatchItem] {
        let byStatus = allItems.filter { $0.status == selectedStatus }
        switch filter {
        case .all:   return byStatus
        case .movie: return byStatus.filter { $0.mediaType == .movie }
        case .tv:    return byStatus.filter { $0.mediaType == .tv && $0.isAnime != true }
        case .anime: return byStatus.filter { $0.mediaType == .tv && $0.isAnime == true }
        }
    }

    /// Count of all items (regardless of media type) for a given status — used for pill badges.
    func count(for status: WatchlistStatus) -> Int {
        allItems.filter { $0.status == status }.count
    }

    /// Fetches the full watchlist. Skips the network if cache is valid unless `forceRefresh` is true.
    func fetchWatchlist(forceRefresh: Bool = false) async {
        guard forceRefresh || store.needsRefresh || store.cachedItems.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let items = try await service.fetchWatchlist(status: nil, mediaType: nil)
            allItems = items
            store.cachedItems = items
            store.needsRefresh = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Instantly refreshes `allItems` from the shared cache.
    /// Called on every appearance so the grid reflects mutations made in the Detail view
    /// (which already refreshed the cache via `refreshStoreCache()`).
    func syncFromCache() {
        let cached = store.cachedItems
        if !cached.isEmpty {
            allItems = cached
        }
    }
}
