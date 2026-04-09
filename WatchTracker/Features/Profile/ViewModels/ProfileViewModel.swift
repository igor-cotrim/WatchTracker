import Foundation

@Observable
@MainActor
final class ProfileViewModel {
    var episodesWatched: Int = 0
    var moviesWatched: Int = 0
    var moviesInWatchlist: Int = 0
    var showsTracking: Int = 0
    var showsCompleted: Int = 0
    var isLoading = false
    var errorMessage: String?

    func fetchStats() async {
        isLoading = true
        errorMessage = nil
        do {
            let stats: ProfileStats = try await APIClient.shared.get(.profileStats)
            episodesWatched = stats.episodesWatched
            moviesWatched = stats.moviesWatched
            moviesInWatchlist = stats.moviesInWatchlist
            showsTracking = stats.showsTracking
            showsCompleted = stats.showsCompleted
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
