import Foundation

protocol ProfileServiceProtocol: Sendable {
    func fetchStats() async throws -> ProfileStats
}
