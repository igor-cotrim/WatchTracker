import Foundation
@testable import WatchTracker

@MainActor
final class MockWatchlistService: WatchlistServiceProtocol {

    // MARK: - Configurable results

    var fetchWatchlistResult: Result<[WatchItem], Error> = .success([])
    var fetchContinueWatchingResult: Result<[ContinueWatchingItem], Error> = .success([])
    var fetchUpcomingResult: Result<[UpcomingItem], Error> = .success([])
    var markEpisodeWatchedResult: Result<WatchlistStatus?, Error> = .success(nil)
    var markAllEpisodesWatchedError: Error? = nil
    var addToWatchlistError: Error? = nil
    var removeFromWatchlistError: Error? = nil
    var updateStatusError: Error? = nil

    // MARK: - Call tracking

    var fetchWatchlistCallCount = 0
    var fetchContinueWatchingCallCount = 0
    var fetchUpcomingCallCount = 0
    var markEpisodeWatchedCalls: [(tvId: Int, season: Int, episode: Int)] = []
    var markAllEpisodesWatchedCalls: [Int] = []
    var addToWatchlistCalls: [(tmdbId: Int, mediaType: MediaType, status: WatchlistStatus)] = []
    var removeFromWatchlistCalls: [Int] = []
    var updateStatusCalls: [(id: Int, status: WatchlistStatus)] = []

    // MARK: - Protocol conformance

    func fetchWatchlist(status: WatchlistStatus?, mediaType: MediaType?) async throws -> [WatchItem] {
        fetchWatchlistCallCount += 1
        return try fetchWatchlistResult.get()
    }

    func fetchContinueWatching() async throws -> [ContinueWatchingItem] {
        fetchContinueWatchingCallCount += 1
        return try fetchContinueWatchingResult.get()
    }

    func fetchUpcoming() async throws -> [UpcomingItem] {
        fetchUpcomingCallCount += 1
        return try fetchUpcomingResult.get()
    }

    @discardableResult
    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus? {
        markEpisodeWatchedCalls.append((tvId: tvId, season: season, episode: episode))
        return try markEpisodeWatchedResult.get()
    }

    func markAllEpisodesWatched(tvId: Int) async throws {
        markAllEpisodesWatchedCalls.append(tvId)
        if let error = markAllEpisodesWatchedError { throw error }
    }

    func addToWatchlist(tmdbId: Int, mediaType: MediaType, status: WatchlistStatus) async throws {
        addToWatchlistCalls.append((tmdbId: tmdbId, mediaType: mediaType, status: status))
        if let error = addToWatchlistError { throw error }
    }

    func removeFromWatchlist(id: Int) async throws {
        removeFromWatchlistCalls.append(id)
        if let error = removeFromWatchlistError { throw error }
    }

    func updateStatus(id: Int, status: WatchlistStatus) async throws {
        updateStatusCalls.append((id: id, status: status))
        if let error = updateStatusError { throw error }
    }
}
