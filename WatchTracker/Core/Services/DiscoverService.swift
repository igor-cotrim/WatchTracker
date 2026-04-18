import Foundation

final class DiscoverService {
    private let api = APIClient.shared

    func fetchTrending(page: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.trending(page: page))
    }

    func search(query: String, type: MediaType? = nil, year: Int? = nil) async throws -> [MediaDetail] {
        try await api.get(.search(query: query, type: type, year: year))
    }

    func discover(provider: String? = nil, type: MediaType? = nil, region: String? = nil) async throws -> [MediaDetail] {
        try await api.get(.discover(provider: provider, type: type, region: region))
    }

    func discoverFiltered(type: MediaType, genres: String? = nil, originCountry: String? = nil, providers: String? = nil, watchRegion: String? = nil, sortBy: String? = nil, page: Int? = nil, releaseDateGte: String? = nil, firstAirDateGte: String? = nil) async throws -> [MediaDetail] {
        try await api.get(.discoverFiltered(type: type, genres: genres, originCountry: originCountry, providers: providers, watchRegion: watchRegion, sortBy: sortBy, page: page, releaseDateGte: releaseDateGte, firstAirDateGte: firstAirDateGte))
    }

    /// Sugar around `discoverFiltered` scoped to a single streaming provider in BR.
    func discoverByProvider(type: MediaType, providerId: Int, sortBy: String? = nil, releaseDateGte: String? = nil, firstAirDateGte: String? = nil, page: Int? = nil) async throws -> [MediaDetail] {
        try await discoverFiltered(
            type: type,
            providers: String(providerId),
            watchRegion: "BR",
            sortBy: sortBy,
            page: page,
            releaseDateGte: releaseDateGte,
            firstAirDateGte: firstAirDateGte
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
