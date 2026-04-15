import Foundation

final class WatchlistService {
    private let api = APIClient.shared

    func fetchWatchlist(status: WatchlistStatus? = nil, mediaType: MediaType? = nil) async throws -> [WatchItem] {
        try await api.get(.watchlist(status: status, mediaType: mediaType?.rawValue))
    }

    func fetchContinueWatching() async throws -> [ContinueWatchingItem] {
        try await api.get(.continueWatching)
    }

    func fetchUpcoming() async throws -> [UpcomingItem] {
        try await api.get(.watchlistUpcoming)
    }

    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws {
        try await api.post(.watchEpisode(tvId: tvId, season: season, episode: episode))
    }

    func markAllEpisodesWatched(tvId: Int) async throws {
        try await api.post(.watchAllEpisodes(tvId: tvId))
    }

    func addToWatchlist(tmdbId: Int, mediaType: MediaType, status: WatchlistStatus) async throws {
        try await api.post(.addToWatchlist(tmdbId: tmdbId, mediaType: mediaType, status: status))
    }

    func removeFromWatchlist(id: Int) async throws {
        try await api.delete(.removeFromWatchlist(id: id))
    }

    func updateStatus(id: Int, status: WatchlistStatus) async throws {
        try await api.patch(.updateWatchlistStatus(id: id, status: status))
    }
}
