import Foundation
import Supabase

extension Notification.Name {
    nonisolated static let authUnauthorized = Notification.Name("authUnauthorized")
}

/// Supplies the bearer token injected into every request. Extracted so tests can
/// drive `APIClient` without touching Supabase (and the keychain).
///
/// `nil` means "no session — send the request anonymously". Throwing means "there is a
/// session but its token could not be obtained", which is a failed request, never an
/// anonymous one: see `supabaseTokenProvider`.
typealias TokenProvider = @Sendable () async throws -> String?

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let tokenProvider: TokenProvider
    private let clock: any Clock<Duration>
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// ISO8601 parser that accepts fractional seconds (e.g. Postgres `timestamptz`
    /// values like `2024-05-01T12:00:00.123456Z`).
    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO8601 parser for timestamps without fractional seconds.
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Reads the access token, refreshing it through Supabase when it has expired.
    ///
    /// The refresh is a network call, so on a weak connection it fails — and swallowing that
    /// into `nil` used to send the request with no `Authorization` header at all. The backend
    /// answered 401, and a 401 signs the user out: losing signal ended the session. Only a
    /// session Supabase says is gone yields `nil` now; a refresh that never got there fails
    /// the request as the connection problem it is.
    static let supabaseTokenProvider: TokenProvider = {
        do {
            return try await SupabaseManager.shared.client.auth.session.accessToken
        } catch {
            guard error.indicatesLostSession else { throw APIError.networkError(error) }
            return nil
        }
    }

    /// The session every request goes through.
    ///
    /// `URLSession.shared` waits 60 seconds before giving up on a request and a week on a
    /// resource, which on a weak connection is a spinner that outlives the user's patience.
    /// These budgets are deliberately short: reads are retried (`send`) and the writes that
    /// matter are queued (`MutationOutbox`), so failing fast costs nothing and frees the UI
    /// to show what it already has.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 45
        // Queuing the request until connectivity returns would hide the offline state the UI
        // is built to show, and the retry policy below is the app's answer instead.
        configuration.waitsForConnectivity = false
        configuration.urlCache = URLCache.shared
        return URLSession(configuration: configuration)
    }

    /// How many extra attempts a retryable request gets after its first failure.
    private static let maxTransientRetries = 2

    init(session: URLSession = APIClient.makeSession(),
         tokenProvider: @escaping TokenProvider = APIClient.supabaseTokenProvider,
         clock: any Clock<Duration> = ContinuousClock()) {
        self.session = session
        self.tokenProvider = tokenProvider
        self.clock = clock
        self.decoder = APIClient.makeDecoder()
        self.encoder = APIClient.makeEncoder()
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = APIClient.iso8601WithFractionalSeconds.date(from: string)
                ?? APIClient.iso8601.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(string)"
            )
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    // MARK: - Public Methods

    func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(for: endpoint)
        return try await perform(request)
    }

    func post<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(for: endpoint)
        return try await perform(request)
    }

    func post(_ endpoint: Endpoint) async throws {
        let request = try await buildRequest(for: endpoint)
        _ = try await send(request)
    }

    func delete<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(for: endpoint)
        return try await perform(request)
    }

    func delete(_ endpoint: Endpoint) async throws {
        let request = try await buildRequest(for: endpoint)
        _ = try await send(request)
    }

    func patch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(for: endpoint)
        return try await perform(request)
    }

    func patch(_ endpoint: Endpoint) async throws {
        let request = try await buildRequest(for: endpoint)
        _ = try await send(request)
    }

    // MARK: - Private Helpers

    private func buildRequest(for endpoint: Endpoint) async throws -> URLRequest {
        let baseURL = await Config.apiBaseURL
        let fullURLString = await baseURL.absoluteString + endpoint.path
        var components = URLComponents(string: fullURLString)!
        let language = Locale.current.language.languageCode?.identifier == "pt" ? "pt-BR" : "en-US"
        let languageItem = URLQueryItem(
            name: "language",
            value: language,
        )
        components.queryItems = (await endpoint.queryItems ?? []) + [languageItem]

        guard let url = components.url else {
            throw APIError.unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = await endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Inject Supabase auth token
        if let token = try await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = await endpoint.body {
            request.httpBody = try encodeBody(body)
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await send(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// Issues a request, retrying only the failures a second attempt can actually fix.
    ///
    /// Three of them, and the eligibility rules differ:
    ///
    /// - **429**: retried once for any method, honouring `Retry-After`. The server asked us to.
    /// - **A dropped or timed-out connection**: the ordinary shape of a weak mobile link
    ///   rather than an exceptional one, so it gets two more attempts with a growing backoff.
    /// - **5xx**: same treatment — a cold backend answers one request badly and the next fine.
    ///
    /// The last two are **reads only**. The backend has no idempotency keys, so a retried
    /// POST is a duplicate row; writes that fail on a bad connection are queued in
    /// `MutationOutbox` instead, where replaying them is the queue's decision to make.
    private func send(_ request: URLRequest) async throws -> Data {
        let isRead = request.httpMethod == HTTPMethod.GET.rawValue
        var rateLimitRetried = false
        var transientAttempts = 0

        while true {
            do {
                let (data, response) = try await session.data(for: request)

                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 429, !rateLimitRetried {
                        rateLimitRetried = true
                        try await clock.sleep(for: APIClient.rateLimitDelay(from: http))
                        continue
                    }
                    if (500...599).contains(http.statusCode),
                       isRead, transientAttempts < APIClient.maxTransientRetries {
                        transientAttempts += 1
                        try await clock.sleep(for: APIClient.backoff(attempt: transientAttempts))
                        continue
                    }
                }

                try APIClient.validateResponse(response)
                return data
            } catch let error as URLError {
                guard isRead, error.isTransient,
                      transientAttempts < APIClient.maxTransientRetries else {
                    // Wrapped rather than rethrown so callers can ask `isConnectivity` instead
                    // of each one re-deriving it from an `NSError` code.
                    throw APIError.networkError(error)
                }
                transientAttempts += 1
                try await clock.sleep(for: APIClient.backoff(attempt: transientAttempts))
            }
        }
    }

    /// `Retry-After` as the server sent it, clamped so a hostile or mistaken header cannot
    /// park the UI on a spinner.
    private static func rateLimitDelay(from response: HTTPURLResponse) -> Duration {
        let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap(Double.init) ?? 1
        return .seconds(min(max(retryAfter, 0), 5))
    }

    /// 0.5s, then 1.5s. Long enough for a handover between cells to settle, short enough that
    /// the whole retry budget still fits inside the resource timeout.
    private static func backoff(attempt: Int) -> Duration {
        .milliseconds(attempt == 1 ? 500 : 1500)
    }

    /// Maps an HTTP response onto `APIError`. `static` so the status-code table can be
    /// unit-tested without going through the network.
    nonisolated static func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            NotificationCenter.default.post(name: .authUnauthorized, object: nil)
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown
        }
    }


    private func encodeBody(_ value: any Encodable & Sendable) throws -> Data {
        func encode<T: Encodable>(_ value: T) throws -> Data {
            try encoder.encode(value)
        }
        return try encode(value)
    }
}
