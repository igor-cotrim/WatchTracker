import Foundation

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var stats: ProfileStats?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: ProfileServiceProtocol

    init(service: ProfileServiceProtocol = ProfileService()) {
        self.service = service
    }

    func fetchStats() async {
        if stats == nil { isLoading = true }
        errorMessage = nil

        do {
            stats = try await service.fetchStats()
        } catch {
            errorMessage = error.userFacingMessage
        }

        isLoading = false
    }
}
