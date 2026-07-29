import Foundation
import Testing
@testable import WatchTracker

@Suite("MediaDetailService", .tags(.async, .service), .timeLimit(.minutes(1)))
struct MediaDetailServiceTests {

    private static let detailJSON = """
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
        "genres": [{"id": 18, "name": "Drama"}],
        "credits": null,
        "watch_providers": null,
        "seasons": null,
        "watchlist_status": "completed"
    }
    """

    /// The shape `SeasonStatusResponse` expects: `message` is non-optional.
    private static func seasonStatus(_ status: String?) -> String {
        """
        {"message": "ok", "status_changed": \(status.map { "\"\($0)\"" } ?? "null")}
        """
    }

    private func service(_ stub: StubURLProtocol.Stub) -> (MediaDetailService, StubURLProtocol.Recorder) {
        let (session, recorder) = StubURLProtocol.session(stub)
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        return (MediaDetailService(api: api), recorder)
    }

    // MARK: - Plain decoding

    @Test func `fetchMediaDetail decodes the detail payload`() async throws {
        let (service, recorder) = service(.json(Self.detailJSON))
        let detail = try await service.fetchMediaDetail(type: .movie, id: 550)

        #expect(detail.id == 550)
        #expect(detail.title == "Fight Club")
        #expect(detail.genres?.first?.name == "Drama")
        #expect(detail.watchlistStatus == .completed)
        #expect(recorder.requests.first?.url?.path.hasSuffix("/media/movie/550") == true)
    }

    @Test func `fetchRecommendations hits the recommendations path`() async throws {
        let (service, recorder) = service(.json("[\(Self.detailJSON)]"))
        let results = try await service.fetchRecommendations(type: .tv, id: 1399)

        #expect(results.count == 1)
        #expect(recorder.requests.first?.url?.path.hasSuffix("/media/tv/1399/recommendations") == true)
    }

    @Test func `fetchSeasonDetail decodes the season payload`() async throws {
        let json = """
        {
            "id": 3624,
            "name": "Season 1",
            "season_number": 1,
            "episode_count": 2,
            "poster_path": null,
            "air_date": null,
            "episodes": [
                {"id": 1, "name": "Pilot", "overview": null, "episode_number": 1,
                 "season_number": 1, "still_path": null, "air_date": null}
            ]
        }
        """
        let (service, recorder) = service(.json(json))
        let season = try await service.fetchSeasonDetail(tvId: 1399, season: 1)

        #expect(season.seasonNumber == 1)
        #expect(season.episodes?.count == 1)
        #expect(recorder.requests.first?.url?.path.hasSuffix("/media/tv/1399/season/1") == true)
    }

    // MARK: - WatchedEpisodesResponse envelope

    @Test func `fetchWatchedEpisodes unwraps the watchedEpisodes envelope`() async throws {
        let (service, recorder) = service(.json(#"{"watched_episodes": [1, 2, 5]}"#))
        let episodes = try await service.fetchWatchedEpisodes(tvId: 1399, season: 1)

        #expect(episodes == [1, 2, 5])
        #expect(recorder.requests.first?.url?.path.hasSuffix("/media/tv/1399/seasons/1/watched") == true)
    }

    @Test func `fetchWatchedEpisodes fails when the envelope key is missing`() async {
        let (service, _) = service(.json(#"[1, 2, 5]"#))
        await #expect(throws: APIError.decodingError) {
            _ = try await service.fetchWatchedEpisodes(tvId: 1, season: 1)
        }
    }

    // MARK: - EpisodeWatchedResponse envelope (no `message` field)

    @Test func `markEpisodeWatched decodes an envelope without a message field`() async throws {
        let (service, recorder) = service(.json(#"{"status_changed": "completed"}"#))
        let status = try await service.markEpisodeWatched(tvId: 1, season: 2, episode: 3)

        #expect(status == .completed)
        #expect(recorder.requests.first?.httpMethod == "POST")
    }

    // MARK: - SeasonStatusResponse envelope

    @Test func `markSeasonWatched unwraps statusChanged`() async throws {
        let (service, recorder) = service(.json(Self.seasonStatus("completed")))
        let status = try await service.markSeasonWatched(tvId: 1399, season: 2)

        #expect(status == .completed)
        #expect(recorder.requests.first?.httpMethod == "POST")
        #expect(recorder.requests.first?.url?.path.hasSuffix("/media/tv/1399/seasons/2/watch") == true)
    }

    @Test func `unmarkSeasonWatched uses DELETE on the same path as marking`() async throws {
        let (service, recorder) = service(.json(Self.seasonStatus(nil)))
        let status = try await service.unmarkSeasonWatched(tvId: 1399, season: 2)

        #expect(status == nil)
        #expect(recorder.requests.first?.httpMethod == "DELETE")
        #expect(recorder.requests.first?.url?.path.hasSuffix("/media/tv/1399/seasons/2/watch") == true)
    }

    @Test func `unmarkEpisodeWatched uses DELETE and unwraps statusChanged`() async throws {
        let (service, recorder) = service(.json(Self.seasonStatus("watching")))
        let status = try await service.unmarkEpisodeWatched(tvId: 1399, season: 1, episode: 4)

        #expect(status == .watching)
        #expect(recorder.requests.first?.httpMethod == "DELETE")
        #expect(recorder.requests.first?.url?.path.hasSuffix("/media/tv/1399/episodes/1/4/watch") == true)
    }

    /// Regression guard: `SeasonStatusResponse.message` is non-optional even though the
    /// service only reads `statusChanged`, so a backend that stops sending `message`
    /// breaks all four season/episode toggles rather than degrading gracefully.
    @Test func `season toggles reject a payload missing the message field`() async {
        let (service, _) = service(.json(#"{"status_changed": "completed"}"#))
        await #expect(throws: APIError.decodingError) {
            _ = try await service.markSeasonWatched(tvId: 1, season: 1)
        }
    }

    // MARK: - Rating

    @Test func `rateMedia POSTs the rating body`() async throws {
        let (service, recorder) = service(.json("{}"))
        try await service.rateMedia(type: .movie, id: 550, rating: 9)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path.hasSuffix("/media/movie/550/rate") == true)

        let body = try #require(recorder.body())
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["rating"] as? Int == 9)
    }

    @Test func `removeRating DELETEs the same path rateMedia POSTs to`() async throws {
        let (service, recorder) = service(.json("{}"))
        try await service.removeRating(type: .movie, id: 550)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path.hasSuffix("/media/movie/550/rate") == true)
    }

    // MARK: - Errors

    @Test func `fetchMediaDetail propagates a not found error`() async {
        let (service, _) = service(.json("{}", statusCode: 404))
        await #expect(throws: APIError.notFound) {
            _ = try await service.fetchMediaDetail(type: .movie, id: 1)
        }
    }
}
