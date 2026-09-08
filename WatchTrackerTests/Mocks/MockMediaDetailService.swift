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
    /// Per-season overrides for the two reads above, for the cases where seasons have to
    /// differ from one another. Anything not listed falls back to the results above.
    var seasonResults: [Int: Season] = [:]
    var watchedEpisodesBySeason: [Int: [Int]] = [:]
    var fetchRecommendationsResult: Result<[MediaDetail], Error> = .success([])
    var fetchPersonResult: Result<PersonDetail, Error> = .success(TestFixtures.person())
    var markEpisodeWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var unmarkEpisodeWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var markSeasonWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var unmarkSeasonWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var rateMediaError: Error? = nil
    var removeRatingError: Error? = nil

    /// Runs inside every write call, before it returns. Both this mock and the
    /// ViewModel are `@MainActor`, so a test can use it to observe the ViewModel's
    /// in-flight state (`pendingEpisodes`, `isSubmittingRating`, …) at the one moment
    /// it is actually set — no real suspension or timing needed.
    var duringCall: (() -> Void)?

    /// The same seam for `fetchSeasonDetail`, which is a read rather than a write: it is
    /// how a test renders a season while its episode list is still in flight.
    var duringSeasonFetch: (() -> Void)?

    // MARK: - Call tracking

    var fetchMediaDetailCalls: [(type: MediaType, id: Int)] = []
    var fetchSeasonDetailCalls: [(tvId: Int, season: Int)] = []
    var fetchWatchedEpisodesCalls: [(tvId: Int, season: Int)] = []
    var fetchRecommendationsCalls: [(type: MediaType, id: Int)] = []
    var fetchPersonCalls: [Int] = []
    var markEpisodeWatchedCalls: [(tvId: Int, season: Int, episode: Int)] = []
    var unmarkEpisodeWatchedCalls: [(tvId: Int, season: Int, episode: Int)] = []
    var markSeasonWatchedCalls: [(tvId: Int, season: Int)] = []
    var unmarkSeasonWatchedCalls: [(tvId: Int, season: Int)] = []
    var rateMediaCalls: [(type: MediaType, id: Int, rating: Int)] = []
    var removeRatingCalls: [(type: MediaType, id: Int)] = []

    // MARK: - Protocol conformance

    func fetchMediaDetail(type: MediaType, id: Int) async throws -> MediaDetail {
        fetchMediaDetailCalls.append((type: type, id: id))
        return try fetchMediaDetailResult.get()
    }

    func fetchSeasonDetail(tvId: Int, season: Int) async throws -> Season {
        fetchSeasonDetailCalls.append((tvId: tvId, season: season))
        duringSeasonFetch?()
        if let override = seasonResults[season] { return override }
        return try fetchSeasonDetailResult.get()
    }

    func fetchWatchedEpisodes(tvId: Int, season: Int) async throws -> [Int] {
        fetchWatchedEpisodesCalls.append((tvId: tvId, season: season))
        if let override = watchedEpisodesBySeason[season] { return override }
        return try fetchWatchedEpisodesResult.get()
    }

    func fetchRecommendations(type: MediaType, id: Int) async throws -> [MediaDetail] {
        fetchRecommendationsCalls.append((type: type, id: id))
        return try fetchRecommendationsResult.get()
    }

    func fetchPerson(id: Int) async throws -> PersonDetail {
        fetchPersonCalls.append(id)
        return try fetchPersonResult.get()
    }

    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus? {
        markEpisodeWatchedCalls.append((tvId: tvId, season: season, episode: episode))
        duringCall?()
        return try markEpisodeWatchedResult.get()
    }

    func unmarkEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus? {
        unmarkEpisodeWatchedCalls.append((tvId: tvId, season: season, episode: episode))
        duringCall?()
        return try unmarkEpisodeWatchedResult.get()
    }

    func markSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus? {
        markSeasonWatchedCalls.append((tvId: tvId, season: season))
        duringCall?()
        return try markSeasonWatchedResult.get()
    }

    func unmarkSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus? {
        unmarkSeasonWatchedCalls.append((tvId: tvId, season: season))
        duringCall?()
        return try unmarkSeasonWatchedResult.get()
    }

    func rateMedia(type: MediaType, id: Int, rating: Int) async throws {
        rateMediaCalls.append((type: type, id: id, rating: rating))
        duringCall?()
        if let error = rateMediaError { throw error }
    }

    func removeRating(type: MediaType, id: Int) async throws {
        removeRatingCalls.append((type: type, id: id))
        duringCall?()
        if let error = removeRatingError { throw error }
    }
}
