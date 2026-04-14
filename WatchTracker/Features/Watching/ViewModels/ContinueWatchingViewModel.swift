import Foundation

@Observable
@MainActor
final class ContinueWatchingViewModel {
    var items: [ContinueWatchingItem] = []
    var isLoading = false
    var errorMessage: String?

    private let service = WatchlistService()

    func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await service.fetchContinueWatching()
                .filter { $0.nextEpisode?.isReleased != false }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markAsWatched(_ item: ContinueWatchingItem) async {
        guard let next = item.nextEpisode else { return }
        do {
            try await service.markEpisodeWatched(
                tvId: item.tmdbId,
                season: next.seasonNumber,
                episode: next.episodeNumber
            )
            await fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
