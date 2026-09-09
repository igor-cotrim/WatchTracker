import Foundation

protocol DiscoverServiceProtocol: Sendable {
    func fetchTrending(page: Int?) async throws -> [MediaDetail]
    func search(query: String, type: MediaType?, year: Int?) async throws -> [MediaDetail]
    func discover(provider: String?, type: MediaType?, region: String?) async throws -> [MediaDetail]
    func discoverFiltered(_ query: DiscoverQuery) async throws -> [MediaDetail]
    func fetchNowPlaying(page: Int?) async throws -> [MediaDetail]
    func fetchTopRated(type: MediaType, page: Int?) async throws -> [MediaDetail]
    func fetchUpcoming(page: Int?) async throws -> [MediaDetail]
    func fetchPopular(type: MediaType, page: Int?) async throws -> [MediaDetail]
    func fetchGenres(type: MediaType) async throws -> [Genre]
    func fetchProviders(type: MediaType) async throws -> [StreamingProvider]
}

final class DiscoverService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func fetchTrending(page: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.trending(page: page))
    }

    func search(query: String, type: MediaType? = nil, year: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.search(query: query, type: type, year: year))
    }

    func discover(provider: String? = nil, type: MediaType? = nil, region: String? = nil) async throws -> [MediaDetail] {
        try await api.get(.discover(provider: provider, type: type, region: region))
    }

    func discoverFiltered(_ query: DiscoverQuery) async throws -> [MediaDetail] {
        try await api.get(.discoverFiltered(query))
    }

    /// Sugar around `discoverFiltered` scoped to a single streaming provider in BR.
    func discoverByProvider(type: MediaType, providerId: Int, sortBy: String? = nil, releaseDateGte: String? = nil, firstAirDateGte: String? = nil, page: Int? = nil) async throws -> [MediaDetail] {
        try await discoverFiltered(
            DiscoverQuery(
                type: type,
                providers: String(providerId),
                watchRegion: MediaMerge.watchRegion,
                sortBy: sortBy,
                page: page,
                releaseDateGte: releaseDateGte,
                firstAirDateGte: firstAirDateGte
            )
        )
    }

    func fetchNowPlaying(page: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.nowPlaying(page: page))
    }

    func fetchTopRated(type: MediaType = .movie, page: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.topRated(type: type, page: page))
    }

    func fetchUpcoming(page: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.upcoming(page: page))
    }

    func fetchPopular(type: MediaType = .movie, page: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.popular(type: type, page: page))
    }

    func fetchGenres(type: MediaType = .movie) async throws -> [Genre] {
        try await api.get(.genres(type: type))
    }

    func fetchProviders(type: MediaType = .movie) async throws -> [StreamingProvider] {
        try await api.get(.providers(type: type))
    }
}

extension DiscoverService: DiscoverServiceProtocol {}

/// Offline double for `#Preview` and `AppContainer.preview`.
struct PreviewDiscoverService: DiscoverServiceProtocol {
    func fetchTrending(page: Int?) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func search(query: String, type: MediaType?, year: Int?) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func discover(provider: String?, type: MediaType?, region: String?) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func discoverFiltered(_ query: DiscoverQuery) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func fetchNowPlaying(page: Int?) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func fetchTopRated(type: MediaType, page: Int?) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func fetchUpcoming(page: Int?) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func fetchPopular(type: MediaType, page: Int?) async throws -> [MediaDetail] { PreviewLibrary.catalogue }
    func fetchGenres(type: MediaType) async throws -> [Genre] { PreviewLibrary.genres }
    func fetchProviders(type: MediaType) async throws -> [StreamingProvider] { PreviewLibrary.providers }
}
