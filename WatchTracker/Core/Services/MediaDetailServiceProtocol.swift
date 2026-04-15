import Foundation

protocol MediaDetailServiceProtocol: Sendable {
    func fetchMediaDetail(type: MediaType, id: Int) async throws -> MediaDetail
    func fetchSeasonDetail(tvId: Int, season: Int) async throws -> Season
    func fetchWatchedEpisodes(tvId: Int, season: Int) async throws -> [Int]
    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus?
    func unmarkEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus?
    func markSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus?
    func unmarkSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus?
    func rateMedia(type: MediaType, id: Int, rating: Int) async throws
}
