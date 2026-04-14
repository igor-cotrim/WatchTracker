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
    var selectedStatus: WatchlistStatus? = nil
    var errorMessage: String?

    private let service = WatchlistService()

    /// Returns items filtered by the current status pill and the given media filter.
    /// All filtering is done in-memory — no network call.
    func items(for filter: MediaFilter) -> [WatchItem] {
        let byStatus: [WatchItem]
        if let status = selectedStatus {
            byStatus = allItems.filter { $0.status == status }
        } else {
            byStatus = allItems
        }
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

    /// Fetches the full watchlist once. Status/media filtering is done in-memory.
    func fetchWatchlist() async {
        isLoading = true
        errorMessage = nil
        do {
            allItems = try await service.fetchWatchlist()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func removeItem(id: Int) async {
        do {
            try await service.removeFromWatchlist(id: id)
            allItems.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
