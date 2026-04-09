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
    var watchlist: [WatchItem] = []
    var isLoading = false
    var selectedFilter: MediaFilter = .all
    var selectedStatus: WatchlistStatus? = nil
    var errorMessage: String?

    private let service = WatchlistService()

    var filteredWatchlist: [WatchItem] {
        switch selectedFilter {
        case .all:
            return watchlist
        case .movie:
            return watchlist.filter { $0.mediaType == .movie }
        case .tv:
            return watchlist.filter { $0.mediaType == .tv && $0.isAnime != true }
        case .anime:
            return watchlist.filter { $0.mediaType == .tv && $0.isAnime == true }
        }
    }

    func fetchWatchlist() async {
        isLoading = true
        errorMessage = nil
        do {
            watchlist = try await service.fetchWatchlist(status: selectedStatus)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func removeItem(id: Int) async {
        do {
            try await service.removeFromWatchlist(id: id)
            watchlist.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
