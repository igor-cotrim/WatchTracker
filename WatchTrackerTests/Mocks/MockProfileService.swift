import Foundation
@testable import WatchTracker

@MainActor
final class MockProfileService: ProfileServiceProtocol {
    var fetchStatsResult: Result<ProfileStats, Error> = .success(TestFixtures.profileStats())
    private(set) var fetchStatsCallCount = 0

    func fetchStats() async throws -> ProfileStats {
        fetchStatsCallCount += 1
        return try fetchStatsResult.get()
    }
}
