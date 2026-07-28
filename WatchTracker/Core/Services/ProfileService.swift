import Foundation

protocol ProfileServiceProtocol: Sendable {
    func fetchStats() async throws -> ProfileStats
}

final class ProfileService {
    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func fetchStats() async throws -> ProfileStats {
        try await api.get(.profileStats)
    }
}

extension ProfileService: ProfileServiceProtocol {}
