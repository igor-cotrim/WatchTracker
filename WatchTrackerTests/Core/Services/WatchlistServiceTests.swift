import Foundation
import Testing
@testable import WatchTracker

@Suite("WatchlistService", .tags(.async, .service), .timeLimit(.minutes(1)))
struct WatchlistServiceTests {

    private static let watchlistJSON = """
    [
        {
            "id": 1,
            "user_id": "test-user",
            "tmdb_id": 550,
            "media_type": "movie",
            "status": "completed",
            "added_at": "2026-01-01T00:00:00Z",
            "title": "Fight Club",
            "poster_path": "/fc.jpg",
            "new_episodes_count": null,
            "is_anime": null
        }
    ]
    """

    private func service(_ stub: StubURLProtocol.Stub) -> (WatchlistService, StubURLProtocol.Recorder) {
        let (session, recorder) = StubURLProtocol.session(stub)
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        return (WatchlistService(api: api), recorder)
    }

    // MARK: - Fetching

    @Test func `fetchWatchlist decodes the item payload`() async throws {
        let (service, _) = service(.json(Self.watchlistJSON))
        let items = try await service.fetchWatchlist()

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.id == 1)
        #expect(item.tmdbId == 550)
        #expect(item.mediaType == .movie)
        #expect(item.status == .completed)
        #expect(item.title == "Fight Club")
    }

    @Test func `fetchWatchlist without filters sends no status or media_type`() async throws {
        let (service, recorder) = service(.json(Self.watchlistJSON))
        _ = try await service.fetchWatchlist()

        let request = try #require(recorder.requests.first)
        let query = request.url?.query ?? ""
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path.hasSuffix(Endpoint.continueWatching.path) == false)
        #expect(!query.contains("status="))
        #expect(!query.contains("media_type="))
    }

    @Test func `fetchWatchlist forwards status and mediaType as query items`() async throws {
        let (service, recorder) = service(.json(Self.watchlistJSON))
        _ = try await service.fetchWatchlist(status: .watching, mediaType: .tv)

        let url = try #require(recorder.requests.first?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "status", value: WatchlistStatus.watching.rawValue)))
        #expect(items.contains(URLQueryItem(name: "media_type", value: MediaType.tv.rawValue)))
    }

    @Test func `fetchContinueWatching decodes the payload`() async throws {
        let json = """
        [
            {
                "id": 3,
                "tmdb_id": 95396,
                "title": "Severance",
                "poster_path": null,
                "is_anime": false,
                "next_episode": {
                    "season_number": 2,
                    "episode_number": 4,
                    "name": "Woe's Hollow",
                    "still_path": null,
                    "air_date": null
                }
            }
        ]
        """
        let (service, recorder) = service(.json(json))
        let items = try await service.fetchContinueWatching()

        let item = try #require(items.first)
        #expect(item.tmdbId == 95396)
        #expect(item.nextEpisode?.seasonNumber == 2)
        #expect(item.nextEpisode?.episodeNumber == 4)
        #expect(recorder.requests.first?.url?.path.hasSuffix(Endpoint.continueWatching.path) == true)
    }

    @Test func `fetchUpcoming decodes the payload`() async throws {
        let json = """
        [
            {
                "tmdb_id": 1399,
                "title": "Test Show",
                "poster_path": null,
                "is_anime": true,
                "next_episode": {
                    "season_number": 1,
                    "episode_number": 2,
                    "name": "Next One",
                    "air_date": "\(TestFixtures.tomorrowDateString())",
                    "still_path": null,
                    "days_until_air": 1
                },
                "watch_providers": ["Netflix"]
            }
        ]
        """
        let (service, recorder) = service(.json(json))
        let items = try await service.fetchUpcoming()

        let item = try #require(items.first)
        #expect(item.tmdbId == 1399)
        #expect(item.isAnime == true)
        #expect(item.watchProviders == ["Netflix"])
        #expect(recorder.requests.first?.url?.path.hasSuffix(Endpoint.watchlistUpcoming.path) == true)
    }

    // MARK: - markEpisodeWatched envelope

    @Test func `markEpisodeWatched unwraps statusChanged from the envelope`() async throws {
        let (service, _) = service(.json(#"{"status_changed": "completed"}"#))
        let status = try await service.markEpisodeWatched(tvId: 1, season: 1, episode: 1)

        #expect(status == .completed)
    }

    @Test func `markEpisodeWatched returns nil when the backend reports no transition`() async throws {
        let (service, _) = service(.json(#"{"status_changed": null}"#))
        let status = try await service.markEpisodeWatched(tvId: 1, season: 1, episode: 1)

        #expect(status == nil)
    }

    @Test func `markEpisodeWatched POSTs to the episode watch endpoint`() async throws {
        let (service, recorder) = service(.json(#"{"status_changed": null}"#))
        _ = try await service.markEpisodeWatched(tvId: 42, season: 3, episode: 7)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path.hasSuffix("/media/tv/42/episodes/3/7/watch") == true)
    }

    // MARK: - Mutations

    @Test func `addToWatchlist encodes the body in snake_case`() async throws {
        let (service, recorder) = service(.json("{}"))
        try await service.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .planToWatch)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "POST")

        let body = try #require(recorder.body())
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["tmdb_id"] as? Int == 550)
        #expect(json["media_type"] as? String == MediaType.movie.rawValue)
        #expect(json["status"] as? String == WatchlistStatus.planToWatch.rawValue)
    }

    @Test func `removeFromWatchlist issues a DELETE against the item path`() async throws {
        let (service, recorder) = service(.json("{}"))
        try await service.removeFromWatchlist(id: 9)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path.hasSuffix("/watchlist/9") == true)
    }

    @Test func `updateStatus issues a PATCH carrying the new status`() async throws {
        let (service, recorder) = service(.json("{}"))
        try await service.updateStatus(id: 9, status: .watching)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path.hasSuffix("/watchlist/9/status") == true)

        let body = try #require(recorder.body())
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["status"] as? String == WatchlistStatus.watching.rawValue)
    }

    @Test func `markAllEpisodesWatched POSTs to the watch-all endpoint`() async throws {
        let (service, recorder) = service(.json("{}"))
        try await service.markAllEpisodesWatched(tvId: 7)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path.hasSuffix("/media/tv/7/watch-all") == true)
    }

    // MARK: - Errors

    @Test func `fetchWatchlist propagates API errors`() async {
        let (service, _) = service(.json("{}", statusCode: 500))
        await #expect(throws: APIError.serverError) {
            _ = try await service.fetchWatchlist()
        }
    }

    @Test func `fetchWatchlist surfaces a decoding error for a malformed payload`() async {
        let (service, _) = service(.json(#"{"not":"an array"}"#))
        await #expect(throws: APIError.decodingError) {
            _ = try await service.fetchWatchlist()
        }
    }
}
