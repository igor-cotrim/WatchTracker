import Foundation
@testable import WatchTracker

struct DiscoverFilteredCall {
    let type: MediaType
    let genres: String?
    let originCountry: String?
    let providers: String?
    let watchRegion: String?
    let sortBy: String?
    let page: Int?
    let releaseDateGte: String?
    let firstAirDateGte: String?
}

@MainActor
final class MockDiscoverService: DiscoverServiceProtocol {

    // MARK: - Configurable results

    var fetchTrendingResult: Result<[MediaDetail], Error> = .success([])
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
    var lastSearchQuery: String? = nil
    var discoverFilteredCalls: [DiscoverFilteredCall] = []

    // MARK: - Protocol conformance

    func fetchTrending(page: Int?) async throws -> [MediaDetail] {
        try fetchTrendingResult.get()
    }

    func search(query: String, type: MediaType?, year: Int?) async throws -> [MediaDetail] {
        searchCallCount += 1
        lastSearchQuery = query
        return try searchResult.get()
    }

    func discover(provider: String?, type: MediaType?, region: String?) async throws -> [MediaDetail] {
        try discoverResult.get()
    }

    func discoverFiltered(type: MediaType, genres: String?, originCountry: String?, providers: String?, watchRegion: String?, sortBy: String?, page: Int?, releaseDateGte: String?, firstAirDateGte: String?) async throws -> [MediaDetail] {
        discoverFilteredCalls.append(DiscoverFilteredCall(
            type: type,
            genres: genres,
            originCountry: originCountry,
            providers: providers,
            watchRegion: watchRegion,
            sortBy: sortBy,
            page: page,
            releaseDateGte: releaseDateGte,
            firstAirDateGte: firstAirDateGte
        ))
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
