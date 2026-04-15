import Foundation

@Observable
@MainActor
final class ContinueWatchingViewModel {
    var items: [ContinueWatchingItem] = []
    var isLoading = false
    var errorMessage: String?

    private let service: any WatchlistServiceProtocol
    private let store: WatchlistStore

    init(
        service: any WatchlistServiceProtocol = WatchlistService(),
        store: WatchlistStore = .shared
    ) {
        self.service = service
        self.store = store
    }

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
            let statusChanged = try await service.markEpisodeWatched(
                tvId: item.tmdbId,
                season: next.seasonNumber,
                episode: next.episodeNumber
            )
            // When the backend transitions the show's status (e.g. watching → completed),
            // refresh the shared cache so Home and Detail reflect the change immediately.
            if statusChanged != nil {
                await refreshWatchlistCache()
            }
            await fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func refreshWatchlistCache() async {
        do {
            let items = try await service.fetchWatchlist(status: nil, mediaType: nil)
            store.cachedItems = items
            store.needsRefresh = false
        } catch {
            store.needsRefresh = true
        }
    }
}
