import Foundation

final class DiscoverService {
    private let api = APIClient.shared

    func fetchTrending() async throws -> [MediaDetail] {
        try await api.get(.trending)
    }

    func search(query: String) async throws -> [MediaDetail] {
        try await api.get(.search(query: query))
    }

    func discover(provider: String? = nil, type: String? = nil, region: String? = nil) async throws -> [MediaDetail] {
        try await api.get(.discover(provider: provider, type: type, region: region))
    }

    func fetchNowPlaying() async throws -> [MediaDetail] {
        try await api.get(.nowPlaying)
    }
}
