import Foundation
import Supabase

actor APIClient {
    static let shared = APIClient()

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
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
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    func delete(_ endpoint: Endpoint) async throws {
        let request = try await buildRequest(for: endpoint)
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Private Helpers

    private func buildRequest(for endpoint: Endpoint) async throws -> URLRequest {
        let baseURL = await Config.apiBaseURL
        let fullURLString = await baseURL.absoluteString + endpoint.path
        var components = URLComponents(string: fullURLString)!
        components.queryItems = await endpoint.queryItems

        guard let url = components.url else {
            throw APIError.unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = await endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Inject Supabase auth token
        if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = await endpoint.body {
            request.httpBody = try encodeBody(body)
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
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
