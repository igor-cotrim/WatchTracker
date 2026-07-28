import Foundation

@Observable
@MainActor
final class ProfileViewModel {
    private(set) var stats: ProfileStats?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func fetchStats() async {
        if stats == nil { isLoading = true }
        errorMessage = nil

        do {
            stats = try await APIClient.shared.get(.profileStats)
        } catch {
            errorMessage = error.userFacingMessage
        }

        isLoading = false
    }
}
