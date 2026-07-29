import Foundation
import Testing
@testable import WatchTracker

@Suite("ImportService", .tags(.async, .service), .timeLimit(.minutes(1)))
struct ImportServiceTests {

    private static let resultJSON = """
    {
        "total": 3,
        "matched": 2,
        "imported": {"watchlist": 2, "ratings": 1, "episodes": 0},
        "unmatched": [{"title": "Unknown Film", "year": 1997}]
    }
    """

    private func service(_ stub: StubURLProtocol.Stub = .json(resultJSON)) -> (ImportService, StubURLProtocol.Recorder) {
        let (session, recorder) = StubURLProtocol.session(stub)
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        return (ImportService(api: api), recorder)
    }

    private func decodedBody(_ recorder: StubURLProtocol.Recorder) throws -> [String: Any] {
        let body = try #require(recorder.body())
        return try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @Test func `importBatch decodes the result payload`() async throws {
        let (service, _) = service()
        let result = try await service.importBatch(ImportBatch(items: TestFixtures.importItems(count: 3)))

        #expect(result.total == 3)
        #expect(result.matched == 2)
        #expect(result.imported.watchlist == 2)
        #expect(result.imported.ratings == 1)
        #expect(result.unmatched.count == 1)
        #expect(result.unmatched.first?.title == "Unknown Film")
        #expect(result.unmatched.first?.year == 1997)
    }

    @Test func `importBatch POSTs to the import endpoint`() async throws {
        let (service, recorder) = service()
        _ = try await service.importBatch(ImportBatch(items: TestFixtures.importItems(count: 1)))

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path.hasSuffix(Endpoint.exportData.path) == false)
        #expect(request.url?.path.hasSuffix("/import") == true)
    }

    /// `ImportBatch.source` is derived, not stored — this is the only place it reaches the wire.
    @Test func `importBatch sends the letterboxd source when nothing carries a TMDB id`() async throws {
        let (service, recorder) = service()
        _ = try await service.importBatch(ImportBatch(items: [TestFixtures.importItem(tmdbId: nil)]))

        #expect(try decodedBody(recorder)["source"] as? String == "letterboxd")
    }

    @Test func `importBatch sends the watchtracker source when an item carries a TMDB id`() async throws {
        let (service, recorder) = service()
        _ = try await service.importBatch(ImportBatch(items: [TestFixtures.importItem(tmdbId: 550)]))

        #expect(try decodedBody(recorder)["source"] as? String == "watchtracker")
    }

    @Test func `importBatch sends the watchtracker source when episodes are present`() async throws {
        let (service, recorder) = service()
        _ = try await service.importBatch(
            ImportBatch(items: [TestFixtures.importItem(tmdbId: nil)],
                        episodes: TestFixtures.importEpisodes(count: 2))
        )

        #expect(try decodedBody(recorder)["source"] as? String == "watchtracker")
    }

    @Test func `importBatch encodes items and episodes in snake_case`() async throws {
        let (service, recorder) = service()
        _ = try await service.importBatch(
            ImportBatch(items: TestFixtures.importItems(count: 2),
                        episodes: TestFixtures.importEpisodes(count: 3))
        )

        let json = try decodedBody(recorder)
        #expect((json["items"] as? [[String: Any]])?.count == 2)

        let episodes = try #require(json["episodes"] as? [[String: Any]])
        #expect(episodes.count == 3)
        #expect(episodes.first?["season_number"] as? Int == 1)
        #expect(episodes.first?["tmdb_id"] as? Int == 95396)
    }

    @Test func `importBatch propagates API errors`() async {
        let (service, _) = service(.json("{}", statusCode: 500))
        await #expect(throws: APIError.serverError) {
            _ = try await service.importBatch(ImportBatch(items: TestFixtures.importItems(count: 1)))
        }
    }
}
