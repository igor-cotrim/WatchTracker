import Foundation
import Testing
@testable import WatchTracker

@Suite("DiscoverService", .tags(.async, .service), .timeLimit(.minutes(1)))
struct DiscoverServiceTests {

    private static let mediaListJSON = """
    [
        {
            "id": 550,
            "title": "Fight Club",
            "name": null,
            "overview": "Test overview",
            "poster_path": "/fc.jpg",
            "backdrop_path": null,
            "vote_average": 8.4,
            "release_date": "1999-10-15",
            "first_air_date": null,
            "genres": null,
            "credits": null,
            "watch_providers": null,
            "seasons": null,
            "watchlist_status": null
        }
    ]
    """

    private func service(_ stub: StubURLProtocol.Stub = .json(mediaListJSON)) -> (DiscoverService, StubURLProtocol.Recorder) {
        let (session, recorder) = StubURLProtocol.session(stub)
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        return (DiscoverService(api: api), recorder)
    }

    private func queryItems(_ recorder: StubURLProtocol.Recorder) throws -> [URLQueryItem] {
        let url = try #require(recorder.requests.first?.url)
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    }

    // MARK: - Decoding

    @Test func `search decodes the media payload`() async throws {
        let (service, _) = service()
        let results = try await service.search(query: "fight club")

        let first = try #require(results.first)
        #expect(first.id == 550)
        #expect(first.title == "Fight Club")
    }

    @Test func `search forwards query, type and year`() async throws {
        let (service, recorder) = service()
        _ = try await service.search(query: "dune", type: .movie, year: 2021)

        let items = try queryItems(recorder)
        #expect(items.contains(URLQueryItem(name: "query", value: "dune")))
        #expect(items.contains(URLQueryItem(name: "type", value: MediaType.movie.rawValue)))
        #expect(items.contains(URLQueryItem(name: "year", value: "2021")))
        #expect(recorder.requests.first?.url?.path.hasSuffix(Endpoint.search(query: "", type: nil, year: nil).path) == true)
    }

    @Test func `fetchTrending decodes and omits page when nil`() async throws {
        let (service, recorder) = service()
        let results = try await service.fetchTrending()

        #expect(results.count == 1)
        let items = try queryItems(recorder)
        #expect(!items.contains { $0.name == "page" })
    }

    @Test func `fetchGenres decodes the genre payload`() async throws {
        let (service, recorder) = service(.json(#"[{"id": 28, "name": "Action"}]"#))
        let genres = try await service.fetchGenres(type: .movie)

        let genre = try #require(genres.first)
        #expect(genre.id == 28)
        #expect(genre.name == "Action")

        let items = try queryItems(recorder)
        #expect(items.contains(URLQueryItem(name: "type", value: MediaType.movie.rawValue)))
    }

    @Test func `fetchProviders decodes the provider payload`() async throws {
        let json = #"[{"provider_id": 8, "provider_name": "Netflix", "logo_path": "/n.jpg"}]"#
        let (service, _) = service(.json(json))
        let providers = try await service.fetchProviders(type: .tv)

        let provider = try #require(providers.first)
        #expect(provider.providerId == 8)
        #expect(provider.providerName == "Netflix")
    }

    // MARK: - discoverFiltered query construction

    @Test func `discoverFiltered emits the dotted date parameter names`() async throws {
        let (service, recorder) = service()
        _ = try await service.discoverFiltered(
            type: .movie,
            genres: "28,12",
            originCountry: "JP",
            providers: "8",
            watchRegion: "BR",
            sortBy: "popularity.desc",
            page: 2,
            releaseDateGte: "2024-01-01",
            firstAirDateGte: "2023-06-01"
        )

        let items = try queryItems(recorder)
        #expect(items.contains(URLQueryItem(name: "with_genres", value: "28,12")))
        #expect(items.contains(URLQueryItem(name: "with_origin_country", value: "JP")))
        #expect(items.contains(URLQueryItem(name: "with_watch_providers", value: "8")))
        #expect(items.contains(URLQueryItem(name: "watch_region", value: "BR")))
        #expect(items.contains(URLQueryItem(name: "sort_by", value: "popularity.desc")))
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
        #expect(items.contains(URLQueryItem(name: "primary_release_date.gte", value: "2024-01-01")))
        #expect(items.contains(URLQueryItem(name: "first_air_date.gte", value: "2023-06-01")))
    }

    @Test func `discoverFiltered always sends type and drops nil filters`() async throws {
        let (service, recorder) = service()
        _ = try await service.discoverFiltered(type: .tv)

        let items = try queryItems(recorder)
        #expect(items.contains(URLQueryItem(name: "type", value: MediaType.tv.rawValue)))
        #expect(!items.contains { $0.name == "with_genres" })
        #expect(!items.contains { $0.name == "watch_region" })
    }

    // MARK: - discoverByProvider (not on the protocol, so only reachable here)

    @Test func `discoverByProvider scopes the query to BR and the given provider`() async throws {
        let (service, recorder) = service()
        _ = try await service.discoverByProvider(type: .movie, providerId: 337)

        let items = try queryItems(recorder)
        #expect(items.contains(URLQueryItem(name: "with_watch_providers", value: "337")))
        #expect(items.contains(URLQueryItem(name: "watch_region", value: "BR")))
        #expect(items.contains(URLQueryItem(name: "type", value: MediaType.movie.rawValue)))
    }

    @Test func `discoverByProvider forwards its optional filters through`() async throws {
        let (service, recorder) = service()
        _ = try await service.discoverByProvider(
            type: .tv,
            providerId: 8,
            sortBy: "vote_average.desc",
            releaseDateGte: "2020-01-01",
            firstAirDateGte: "2021-01-01",
            page: 3
        )

        let items = try queryItems(recorder)
        #expect(items.contains(URLQueryItem(name: "sort_by", value: "vote_average.desc")))
        #expect(items.contains(URLQueryItem(name: "page", value: "3")))
        #expect(items.contains(URLQueryItem(name: "primary_release_date.gte", value: "2020-01-01")))
        #expect(items.contains(URLQueryItem(name: "first_air_date.gte", value: "2021-01-01")))
    }

    @Test func `discoverByProvider hits the discover endpoint`() async throws {
        let (service, recorder) = service()
        _ = try await service.discoverByProvider(type: .movie, providerId: 8)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path.hasSuffix("/discover") == true)
    }

    // MARK: - Errors

    @Test func `search propagates API errors`() async {
        let (service, _) = service(.json("{}", statusCode: 429))
        await #expect(throws: APIError.rateLimited) {
            _ = try await service.search(query: "boom")
        }
    }
}
