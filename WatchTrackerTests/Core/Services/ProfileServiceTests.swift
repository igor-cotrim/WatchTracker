import Foundation
import Testing
@testable import WatchTracker

@Suite("ProfileService", .tags(.async, .service), .timeLimit(.minutes(1)))
struct ProfileServiceTests {

    private static let statsJSON = """
    {
        "episodes_watched": 120,
        "movies_watched": 34,
        "shows_completed": 9,
        "titles_rated": 51,
        "average_rating": 7.4
    }
    """

    private func service(_ stub: StubURLProtocol.Stub) -> (ProfileService, StubURLProtocol.Recorder) {
        let (session, recorder) = StubURLProtocol.session(stub)
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        return (ProfileService(api: api), recorder)
    }

    @Test func `fetchStats decodes the profile payload`() async throws {
        let (service, _) = service(.json(Self.statsJSON))
        let stats = try await service.fetchStats()

        #expect(stats.episodesWatched == 120)
        #expect(stats.moviesWatched == 34)
        #expect(stats.showsCompleted == 9)
        #expect(stats.titlesRated == 51)
        #expect(stats.averageRating == 7.4)
    }

    @Test func `fetchStats hits the profile stats endpoint with GET`() async throws {
        let (service, recorder) = service(.json(Self.statsJSON))
        _ = try await service.fetchStats()

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path.hasSuffix(Endpoint.profileStats.path) == true)
    }

    @Test func `fetchStats propagates API errors`() async {
        let (service, _) = service(.json("{}", statusCode: 500))
        await #expect(throws: APIError.serverError) {
            _ = try await service.fetchStats()
        }
    }
}
