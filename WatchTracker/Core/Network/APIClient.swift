import Foundation
import Supabase

extension Notification.Name {
    nonisolated static let authUnauthorized = Notification.Name("authUnauthorized")
}

/// Supplies the bearer token injected into every request. Extracted so tests can
/// drive `APIClient` without touching Supabase (and the keychain).
typealias TokenProvider = @Sendable () async -> String?

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

    static let supabaseTokenProvider: TokenProvider = {
        try? await SupabaseManager.shared.client.auth.session.accessToken
    }

    init(session: URLSession = .shared,
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
        let (_, response) = try await session.data(for: request)
        try APIClient.validateResponse(response)
    }

    func delete<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(for: endpoint)
        return try await perform(request)
    }

    func delete(_ endpoint: Endpoint) async throws {
        let request = try await buildRequest(for: endpoint)
        let (_, response) = try await session.data(for: request)
        try APIClient.validateResponse(response)
    }

    func patch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(for: endpoint)
        return try await perform(request)
    }

    func patch(_ endpoint: Endpoint) async throws {
        let request = try await buildRequest(for: endpoint)
        let (_, response) = try await session.data(for: request)
        try APIClient.validateResponse(response)
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
        if let token = await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = await endpoint.body {
            request.httpBody = try encodeBody(body)
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await sendWithRateLimitRetry(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    private func sendWithRateLimitRetry(_ request: URLRequest) async throws -> Data {
        var (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(Double.init) ?? 1
            try await clock.sleep(for: .seconds(min(max(retryAfter, 0), 5)))
            (data, response) = try await session.data(for: request)
        }

        try APIClient.validateResponse(response)
        return data
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
