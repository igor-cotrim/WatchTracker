import Foundation
@testable import WatchTracker


@MainActor
final class MockDiscoverService: DiscoverServiceProtocol {

    // MARK: - Configurable results

    var fetchTrendingResult: Result<[MediaDetail], Error> = .success([])
    /// Scripted pages for `fetchTrending`, one entry per page number. A request past the
    /// end returns an empty page — the signal a paginated grid uses to stop asking.
    /// Leave nil to fall back to `fetchTrendingResult`.
    var trendingPages: [[MediaDetail]]?
    var searchResult: Result<[MediaDetail], Error> = .success([])
    var discoverResult: Result<[MediaDetail], Error> = .success([])
    var discoverFilteredResult: Result<[MediaDetail], Error> = .success([])
    var fetchNowPlayingResult: Result<[MediaDetail], Error> = .success([])
    var fetchTopRatedResult: Result<[MediaDetail], Error> = .success([])
    var fetchUpcomingResult: Result<[MediaDetail], Error> = .success([])
    var fetchPopularResult: Result<[MediaDetail], Error> = .success([])
    var fetchGenresResult: Result<[Genre], Error> = .success([])
    var fetchProvidersResult: Result<[StreamingProvider], Error> = .success([])

    // MARK: - Call tracking

    var searchCallCount = 0
    var trendingPagesRequested: [Int?] = []
    var lastSearchQuery: String? = nil
    var discoverFilteredCalls: [DiscoverQuery] = []

    // MARK: - Protocol conformance

    func fetchTrending(page: Int?) async throws -> [MediaDetail] {
        trendingPagesRequested.append(page)
        guard let trendingPages else { return try fetchTrendingResult.get() }
        let index = (page ?? 1) - 1
        return trendingPages.indices.contains(index) ? trendingPages[index] : []
    }

    func search(query: String, type: MediaType?, year: Int?) async throws -> [MediaDetail] {
        searchCallCount += 1
        lastSearchQuery = query
        return try searchResult.get()
    }

    func discover(provider: String?, type: MediaType?, region: String?) async throws -> [MediaDetail] {
        try discoverResult.get()
    }

    func discoverFiltered(_ query: DiscoverQuery) async throws -> [MediaDetail] {
        discoverFilteredCalls.append(query)
        return try discoverFilteredResult.get()
    }

    func fetchNowPlaying(page: Int?) async throws -> [MediaDetail] {
        try fetchNowPlayingResult.get()
    }

    func fetchTopRated(type: MediaType, page: Int?) async throws -> [MediaDetail] {
        try fetchTopRatedResult.get()
    }

    func fetchUpcoming(page: Int?) async throws -> [MediaDetail] {
        try fetchUpcomingResult.get()
    }

    func fetchPopular(type: MediaType, page: Int?) async throws -> [MediaDetail] {
        try fetchPopularResult.get()
    }

    func fetchGenres(type: MediaType) async throws -> [Genre] {
        try fetchGenresResult.get()
    }

    func fetchProviders(type: MediaType) async throws -> [StreamingProvider] {
        try fetchProvidersResult.get()
    }
}
