import Foundation

protocol DiscoverServiceProtocol: Sendable {
    func fetchTrending() async throws -> [MediaDetail]
    func search(query: String, type: MediaType?, year: Int?) async throws -> [MediaDetail]
    func discover(provider: String?, type: MediaType?, region: String?) async throws -> [MediaDetail]
    func discoverFiltered(type: MediaType, genres: String?, originCountry: String?, providers: String?, watchRegion: String?, sortBy: String?, page: Int?) async throws -> [MediaDetail]
    func fetchNowPlaying() async throws -> [MediaDetail]
    func fetchTopRated(type: MediaType, page: Int?) async throws -> [MediaDetail]
    func fetchUpcoming(page: Int?) async throws -> [MediaDetail]
    func fetchPopular(type: MediaType, page: Int?) async throws -> [MediaDetail]
    func fetchGenres(type: MediaType) async throws -> [Genre]
    func fetchProviders(type: MediaType) async throws -> [StreamingProvider]
}
