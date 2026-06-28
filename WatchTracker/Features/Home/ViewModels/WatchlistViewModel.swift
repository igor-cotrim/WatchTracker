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
    var allItems: [WatchItem] = [] {
        didSet { rebuildDerived() }
    }
    var isLoading = false
    var selectedFilter: MediaFilter = .all
    var selectedStatus: WatchlistStatus = .watching {
        didSet { rebuildDerived() }
    }
    var errorMessage: String?

    // Precomputed per-filter lists for the current selectedStatus.
    // Updated atomically whenever allItems or selectedStatus changes,
    // so each WatchlistView tab reads a stored array instead of filtering on every render.
    private(set) var filteredAll: [WatchItem] = []
    private(set) var filteredMovies: [WatchItem] = []
    private(set) var filteredTV: [WatchItem] = []
    private(set) var filteredAnime: [WatchItem] = []

    // Precomputed item counts per status — used by StatusFilterBar pills.
    private(set) var countWatching: Int = 0
    private(set) var countPlanToWatch: Int = 0
    private(set) var countCompleted: Int = 0

    private let service: WatchlistServiceProtocol
    private let store: WatchlistStore

    init(
        service: WatchlistServiceProtocol,
        store: WatchlistStore
    ) {
        self.service = service
        self.store = store
        allItems = store.cachedItems
        rebuildDerived()
    }

    /// Returns precomputed items for the given filter under the current selectedStatus.
    func items(for filter: MediaFilter) -> [WatchItem] {
        switch filter {
        case .all:   return filteredAll
        case .movie: return filteredMovies
        case .tv:    return filteredTV
        case .anime: return filteredAnime
        }
    }

    /// Returns the precomputed count for the given status.
    func count(for status: WatchlistStatus) -> Int {
        switch status {
        case .watching:    return countWatching
        case .planToWatch: return countPlanToWatch
        case .completed:   return countCompleted
        }
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
            await notifyRevivedSeasons(in: items)
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

    // MARK: - Private

    /// Fires a local notification for any show the backend just revived from
    /// `completed` to `watching` because a new season aired. Deduping lives in
    /// `NotificationService`, so this is safe to call on every refresh.
    private func notifyRevivedSeasons(in items: [WatchItem]) async {
        for item in items {
            guard let season = item.newSeasonNumber else { continue }
            await NotificationService.shared.notifyNewSeason(
                tmdbId: item.tmdbId,
                title: item.title ?? "",
                seasonNumber: season
            )
        }
    }

    private func rebuildDerived() {
        let byStatus = allItems.filter { $0.status == selectedStatus }
        filteredAll = byStatus
        filteredMovies = byStatus.filter { $0.mediaType == .movie }
        filteredTV = byStatus.filter { $0.mediaType == .tv && $0.isAnime != true }
        filteredAnime = byStatus.filter { $0.mediaType == .tv && $0.isAnime == true }

        countWatching = allItems.filter { $0.status == .watching }.count
        countPlanToWatch = allItems.filter { $0.status == .planToWatch }.count
        countCompleted = allItems.filter { $0.status == .completed }.count
    }
}
