import Foundation
@testable import WatchTracker

enum MockError: Error {
    case notConfigured
    case generic(String)
}

@MainActor
final class MockMediaDetailService: MediaDetailServiceProtocol {

    // MARK: - Configurable results

    var fetchMediaDetailResult: Result<MediaDetail, Error> = .success(TestFixtures.mediaDetail())
    var fetchSeasonDetailResult: Result<Season, Error> = .success(TestFixtures.season())
    var fetchWatchedEpisodesResult: Result<[Int], Error> = .success([])
    var markEpisodeWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var unmarkEpisodeWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var markSeasonWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var unmarkSeasonWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var rateMediaError: Error? = nil

    // MARK: - Call tracking

    var fetchMediaDetailCalls: [(type: MediaType, id: Int)] = []
    var fetchSeasonDetailCalls: [(tvId: Int, season: Int)] = []
    var fetchWatchedEpisodesCalls: [(tvId: Int, season: Int)] = []
    var markEpisodeWatchedCalls: [(tvId: Int, season: Int, episode: Int)] = []
    var unmarkEpisodeWatchedCalls: [(tvId: Int, season: Int, episode: Int)] = []
    var markSeasonWatchedCalls: [(tvId: Int, season: Int)] = []
    var unmarkSeasonWatchedCalls: [(tvId: Int, season: Int)] = []
    var rateMediaCalls: [(type: MediaType, id: Int, rating: Int)] = []

    // MARK: - Protocol conformance

    func fetchMediaDetail(type: MediaType, id: Int) async throws -> MediaDetail {
        fetchMediaDetailCalls.append((type: type, id: id))
        return try fetchMediaDetailResult.get()
    }

    func fetchSeasonDetail(tvId: Int, season: Int) async throws -> Season {
        fetchSeasonDetailCalls.append((tvId: tvId, season: season))
        return try fetchSeasonDetailResult.get()
    }

    func fetchWatchedEpisodes(tvId: Int, season: Int) async throws -> [Int] {
        fetchWatchedEpisodesCalls.append((tvId: tvId, season: season))
        return try fetchWatchedEpisodesResult.get()
    }

    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus? {
        markEpisodeWatchedCalls.append((tvId: tvId, season: season, episode: episode))
        return try markEpisodeWatchedResult.get()
    }

    func unmarkEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus? {
        unmarkEpisodeWatchedCalls.append((tvId: tvId, season: season, episode: episode))
        return try unmarkEpisodeWatchedResult.get()
    }

    func markSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus? {
        markSeasonWatchedCalls.append((tvId: tvId, season: season))
        return try markSeasonWatchedResult.get()
    }

    func unmarkSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus? {
        unmarkSeasonWatchedCalls.append((tvId: tvId, season: season))
        return try unmarkSeasonWatchedResult.get()
    }

    func rateMedia(type: MediaType, id: Int, rating: Int) async throws {
        rateMediaCalls.append((type: type, id: id, rating: rating))
        if let error = rateMediaError { throw error }
    }
}
