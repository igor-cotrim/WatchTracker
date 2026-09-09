import Foundation
import Testing
@testable import WatchTracker

// MARK: - Status code mapping

@Suite("APIClient.validateResponse", .tags(.pure, .service))
struct APIClientValidateResponseTests {

    private func response(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    @Test(arguments: [200, 201, 204, 299])
    func `success codes do not throw`(status: Int) throws {
        try APIClient.validateResponse(response(status))
    }

    @Test(arguments: [
        (404, APIError.notFound),
        (429, APIError.rateLimited),
        (500, APIError.serverError),
        (503, APIError.serverError),
        (599, APIError.serverError),
        (302, APIError.unknown),
        (418, APIError.unknown),
    ])
    func `status maps to APIError`(status: Int, expected: APIError) {
        #expect(throws: expected) {
            try APIClient.validateResponse(response(status))
        }
    }

    @Test func `401 throws unauthorized`() {
        #expect(throws: APIError.unauthorized) {
            try APIClient.validateResponse(response(401))
        }
    }

    @Test func `401 posts the authUnauthorized notification`() async {
        await confirmation("authUnauthorized posted") { confirm in
            let observer = NotificationCenter.default.addObserver(
                forName: .authUnauthorized,
                object: nil,
                queue: nil
            ) { _ in confirm() }
            defer { NotificationCenter.default.removeObserver(observer) }

            #expect(throws: APIError.unauthorized) {
                try APIClient.validateResponse(self.response(401))
            }
        }
    }

    @Test func `non-HTTP response throws unknown`() {
        let response = URLResponse(
            url: URL(string: "https://example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        #expect(throws: APIError.unknown) {
            try APIClient.validateResponse(response)
        }
    }
}

// MARK: - Decoding

@Suite("APIClient decoder", .tags(.pure, .service))
struct APIClientDecoderTests {
    private struct Payload: Decodable, Equatable {
        let someValue: String
        let createdAt: Date
    }

    private func decode(dateString: String) throws -> Payload {
        let json = #"{"some_value": "hi", "created_at": "\#(dateString)"}"#
        return try APIClient.makeDecoder().decode(Payload.self, from: Data(json.utf8))
    }

    @Test func `converts snake_case keys to camelCase`() throws {
        let payload = try decode(dateString: "2026-01-15T12:00:00Z")
        #expect(payload.someValue == "hi")
    }

    @Test func `parses ISO8601 without fractional seconds`() throws {
        let payload = try decode(dateString: "2026-01-15T12:00:00Z")
        #expect(payload.createdAt.timeIntervalSince1970 == 1768478400)
    }

    @Test func `parses ISO8601 with fractional seconds`() throws {
        // Postgres timestamptz values arrive with microsecond precision.
        let payload = try decode(dateString: "2026-01-15T12:00:00.123456Z")
        #expect(Int(payload.createdAt.timeIntervalSince1970) == 1768478400)
    }

    @Test(arguments: ["2026-01-15", "not a date", ""])
    func `rejects unparseable dates`(input: String) {
        #expect(throws: DecodingError.self) {
            try decode(dateString: input)
        }
    }

    @Test func `encoder converts camelCase keys to snake_case`() throws {
        struct Body: Encodable { let tmdbId: Int }
        let data = try APIClient.makeEncoder().encode(Body(tmdbId: 7))
        #expect(String(decoding: data, as: UTF8.self) == #"{"tmdb_id":7}"#)
    }
}

// MARK: - Request/response round trip

@Suite("APIClient requests", .tags(.async, .service), .timeLimit(.minutes(1)))
struct APIClientRequestTests {
    private struct Stats: Decodable {
        let episodesWatched: Int
    }

    private static let statsJSON = """
    {"episodes_watched": 5, "movies_watched": 1, "shows_completed": 0, "titles_rated": 0, "average_rating": 0}
    """

    private func client(
        _ stubs: [StubURLProtocol.Stub],
        token: String? = "test-token"
    ) -> (APIClient, StubURLProtocol.Recorder, ImmediateClock) {
        let (session, recorder) = StubURLProtocol.session(stubs)
        let clock = ImmediateClock()
        let client = APIClient(session: session, tokenProvider: { token }, clock: clock)
        return (client, recorder, clock)
    }

    @Test func `get decodes the response body`() async throws {
        let (client, recorder, _) = client([.json(Self.statsJSON)])
        let stats: Stats = try await client.get(.profileStats)
        #expect(stats.episodesWatched == 5)
        #expect(recorder.requestCount == 1)
    }

    @Test func `injects the bearer token from the token provider`() async throws {
        let (client, recorder, _) = client([.json(Self.statsJSON)], token: "abc123")
        let _: Stats = try await client.get(.profileStats)
        let header = recorder.requests.first?.value(forHTTPHeaderField: "Authorization")
        #expect(header == "Bearer abc123")
    }

    @Test func `omits the Authorization header when there is no token`() async throws {
        let (client, recorder, _) = client([.json(Self.statsJSON)], token: nil)
        let _: Stats = try await client.get(.profileStats)
        #expect(recorder.requests.first?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func `always appends a language query item`() async throws {
        let (client, recorder, _) = client([.json(Self.statsJSON)])
        let _: Stats = try await client.get(.profileStats)
        let url = try #require(recorder.requests.first?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains { $0.name == "language" })
    }

    @Test func `sets the Content-Type header`() async throws {
        let (client, recorder, _) = client([.json(Self.statsJSON)])
        let _: Stats = try await client.get(.profileStats)
        #expect(recorder.requests.first?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func `maps a malformed body to decodingError`() async {
        let (client, _, _) = client([.json(#"{"unexpected": true}"#)])
        await #expect(throws: APIError.decodingError) {
            let _: Stats = try await client.get(.profileStats)
        }
    }

    @Test func `propagates a 404 as notFound`() async {
        let (client, _, _) = client([.json("{}", statusCode: 404)])
        await #expect(throws: APIError.notFound) {
            let _: Stats = try await client.get(.profileStats)
        }
    }

    @Test func `retries once after a 429 and returns the retried body`() async throws {
        let (client, recorder, clock) = client([
            StubURLProtocol.Stub(statusCode: 429, body: Data("{}".utf8), headers: ["Retry-After": "3"]),
            .json(Self.statsJSON),
        ])

        let stats: Stats = try await client.get(.profileStats)

        #expect(stats.episodesWatched == 5)
        #expect(recorder.requestCount == 2)
        #expect(clock.sleeps == [.seconds(3)])
    }

    @Test func `defaults to a one second backoff when Retry-After is missing`() async throws {
        let (client, _, clock) = client([
            .json("{}", statusCode: 429),
            .json(Self.statsJSON),
        ])
        let _: Stats = try await client.get(.profileStats)
        #expect(clock.sleeps == [.seconds(1)])
    }

    @Test func `clamps Retry-After to five seconds`() async throws {
        let (client, _, clock) = client([
            StubURLProtocol.Stub(statusCode: 429, body: Data("{}".utf8), headers: ["Retry-After": "600"]),
            .json(Self.statsJSON),
        ])
        let _: Stats = try await client.get(.profileStats)
        #expect(clock.sleeps == [.seconds(5)])
    }

    @Test func `gives up with rateLimited when the retry is also 429`() async {
        let (client, recorder, _) = client([.json("{}", statusCode: 429)])
        await #expect(throws: APIError.rateLimited) {
            let _: Stats = try await client.get(.profileStats)
        }
        #expect(recorder.requestCount == 2, "Should retry exactly once")
    }

    @Test func `void post validates the response without decoding`() async throws {
        let (client, recorder, _) = client([.json("", statusCode: 204)])
        try await client.post(.watchEpisode(tvId: 1, season: 1, episode: 1))
        #expect(recorder.requests.first?.httpMethod == "POST")
    }

    @Test func `void delete surfaces server errors`() async {
        let (client, _, _) = client([.json("{}", statusCode: 500)])
        await #expect(throws: APIError.serverError) {
            try await client.delete(.removeFromWatchlist(id: 1))
        }
    }

    // MARK: - Weak connections

    @Test func `retries a read that lost its connection and returns the retried body`() async throws {
        let (client, recorder, clock) = client([
            .failing(.networkConnectionLost),
            .json(Self.statsJSON),
        ])

        let stats: Stats = try await client.get(.profileStats)

        #expect(stats.episodesWatched == 5)
        #expect(recorder.requestCount == 2)
        #expect(clock.sleeps == [.milliseconds(500)])
    }

    @Test func `gives up after two retries and reports a connectivity failure`() async {
        let (client, recorder, clock) = client([.failing(.timedOut)])

        await #expect(throws: APIError.self) {
            let _: Stats = try await client.get(.profileStats)
        }

        #expect(recorder.requestCount == 3, "The first attempt plus two retries")
        #expect(clock.sleeps == [.milliseconds(500), .milliseconds(1500)])
    }

    @Test func `wraps a transport failure as a connectivity APIError`() async throws {
        let (client, _, _) = client([.failing(.notConnectedToInternet)])

        let error: (any Error)? = await {
            do {
                let _: Stats = try await client.get(.profileStats)
                return nil
            } catch {
                return error
            }
        }()

        let apiError = try #require(error as? APIError)
        #expect(apiError.isConnectivity)
        #expect(apiError.userFacingMessage == Strings.Common.connectionError)
    }

    /// The backend has no idempotency keys, so a retried write is a duplicate row.
    @Test func `never retries a write that lost its connection`() async {
        let (client, recorder, _) = client([.failing(.networkConnectionLost)])

        await #expect(throws: APIError.self) {
            try await client.post(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .planToWatch))
        }

        #expect(recorder.requestCount == 1)
    }

    @Test func `retries a read that hit a 5xx`() async throws {
        let (client, recorder, _) = client([
            .json("{}", statusCode: 502),
            .json(Self.statsJSON),
        ])

        let stats: Stats = try await client.get(.profileStats)

        #expect(stats.episodesWatched == 5)
        #expect(recorder.requestCount == 2)
    }

    @Test func `does not retry a write that hit a 5xx`() async {
        let (client, recorder, _) = client([.json("{}", statusCode: 500)])

        await #expect(throws: APIError.serverError) {
            try await client.delete(.removeFromWatchlist(id: 1))
        }

        #expect(recorder.requestCount == 1)
    }

    /// A `.cancelled` request is a dismissed screen or a superseded debounce, not a bad link.
    @Test func `does not retry a cancelled request`() async {
        let (client, recorder, _) = client([.failing(.cancelled)])

        await #expect(throws: APIError.self) {
            let _: Stats = try await client.get(.profileStats)
        }

        #expect(recorder.requestCount == 1)
    }

    /// Losing the connection must never degrade into an anonymous request: the backend
    /// answers 401, and a 401 signs the user out.
    @Test func `sends nothing when the token provider fails`() async {
        let (session, recorder) = StubURLProtocol.session([.json(Self.statsJSON)])
        let client = APIClient(
            session: session,
            tokenProvider: { throw APIError.networkError(URLError(.notConnectedToInternet)) },
            clock: ImmediateClock()
        )

        await #expect(throws: APIError.self) {
            let _: Stats = try await client.get(.profileStats)
        }

        #expect(recorder.requestCount == 0)
    }

    @Test func `encodes the endpoint body into the request`() async throws {
        let (client, recorder, _) = client([.json("", statusCode: 200)])
        try await client.post(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .planToWatch))

        let body = try #require(recorder.body())
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["tmdb_id"] as? Int == 550)
        #expect(json["media_type"] as? String == "movie")
        #expect(json["status"] as? String == "plan_to_watch")
    }
}
