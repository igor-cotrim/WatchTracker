import Foundation

protocol WatchlistServiceProtocol: Sendable {
    func fetchWatchlist(status: WatchlistStatus?, mediaType: MediaType?) async throws -> [WatchItem]
    func fetchContinueWatching() async throws -> [ContinueWatchingItem]
    func fetchUpcoming() async throws -> [UpcomingItem]
    @discardableResult
    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus?
    func markAllEpisodesWatched(tvId: Int) async throws
    func addToWatchlist(tmdbId: Int, mediaType: MediaType, status: WatchlistStatus) async throws
    func removeFromWatchlist(id: Int) async throws
    func updateStatus(id: Int, status: WatchlistStatus) async throws
}
