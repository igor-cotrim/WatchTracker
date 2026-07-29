import Foundation
import Testing
@testable import WatchTracker

@Suite("ExportService", .tags(.async, .service), .timeLimit(.minutes(1)))
struct ExportServiceTests {

    private static let payloadJSON = """
    {
        "generated_at": "2026-07-28T12:00:00Z",
        "unresolved": 2,
        "items": [
            {
                "tmdb_id": 550,
                "media_type": "movie",
                "title": "Fight Club",
                "year": 1999,
                "status": "completed",
                "rating": 9,
                "added_at": "2026-01-02T10:00:00Z",
                "rated_at": "2026-01-03T10:00:00Z"
            }
        ],
        "episodes": [
            {
                "tmdb_id": 95396,
                "season_number": 1,
                "episode_number": 4,
                "watched_at": "2026-02-01T00:00:00Z"
            }
        ]
    }
    """

    private func service(_ stub: StubURLProtocol.Stub = .json(payloadJSON)) -> (ExportService, StubURLProtocol.Recorder) {
        let (session, recorder) = StubURLProtocol.session(stub)
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        return (ExportService(api: api), recorder)
    }

    @Test func `fetchExport decodes items, episodes and the unresolved count`() async throws {
        let (service, _) = service()
        let payload = try await service.fetchExport()

        #expect(payload.unresolved == 2)
        #expect(payload.items.count == 1)
        #expect(payload.episodes.count == 1)

        let item = try #require(payload.items.first)
        #expect(item.tmdbId == 550)
        #expect(item.mediaType == .movie)
        #expect(item.rating == 9)

        let episode = try #require(payload.episodes.first)
        #expect(episode.tmdbId == 95396)
        #expect(episode.episodeNumber == 4)
    }

    @Test func `fetchExport hits the export endpoint with GET`() async throws {
        let (service, recorder) = service()
        _ = try await service.fetchExport()

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path.hasSuffix(Endpoint.exportData.path) == true)
    }

    @Test func `fetchExport propagates API errors`() async {
        let (service, _) = service(.json("{}", statusCode: 401))
        await #expect(throws: APIError.unauthorized) {
            _ = try await service.fetchExport()
        }
    }
}
