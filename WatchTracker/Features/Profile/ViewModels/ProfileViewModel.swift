import Foundation

@Observable
final class ProfileViewModel {
    var episodesWatched: Int = 0
    var moviesWatched: Int = 0
    var showsTracking: Int = 0
    var totalHours: Double = 0.0
    var isLoading = false

    func fetchStats() async {
        // TODO: Fetch user stats from API
        isLoading = true
        // Placeholder values
        episodesWatched = 0
        moviesWatched = 0
        showsTracking = 0
        totalHours = 0.0
        isLoading = false
    }
}
