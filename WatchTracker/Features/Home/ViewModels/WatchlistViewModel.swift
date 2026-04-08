import Foundation

enum MediaFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case movie = "Movies"
    case tv = "Series"

    var id: String { rawValue }
}

@Observable
@MainActor
final class WatchlistViewModel {
    var watchlist: [WatchItem] = []
    var isLoading = false
    var selectedFilter: MediaFilter = .all
    var errorMessage: String?

    private let service = WatchlistService()

    var filteredWatchlist: [WatchItem] {
        switch selectedFilter {
        case .all:
            return watchlist
        case .movie:
            return watchlist.filter { $0.mediaType == .movie }
        case .tv:
            return watchlist.filter { $0.mediaType == .tv }
        }
    }

    func fetchWatchlist() async {
        isLoading = true
        errorMessage = nil
        do {
            watchlist = try await service.fetchWatchlist()
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
