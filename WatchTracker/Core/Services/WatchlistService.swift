import Foundation

final class WatchlistService {
    private let api = APIClient.shared

    func fetchWatchlist(status: WatchlistStatus? = nil, mediaType: MediaType? = nil) async throws -> [WatchItem] {
        try await api.get(.watchlist)
    }

    func addToWatchlist(tmdbId: Int, mediaType: MediaType, status: WatchlistStatus) async throws {
        try await api.post(.addToWatchlist(tmdbId: tmdbId, mediaType: mediaType, status: status))
    }

    func removeFromWatchlist(id: Int) async throws {
        try await api.delete(.removeFromWatchlist(id: id))
    }
}
