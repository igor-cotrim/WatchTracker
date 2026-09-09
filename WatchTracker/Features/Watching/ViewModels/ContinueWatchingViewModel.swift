import Foundation

@Observable
@MainActor
final class ContinueWatchingViewModel {
    private(set) var items: [ContinueWatchingItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: WatchlistServiceProtocol
    private let store: WatchlistStore

    init(
        service: WatchlistServiceProtocol,
        store: WatchlistStore
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
                .sorted { first, second in
                    let firstAirDate = first.nextEpisode?.airDateValue ?? .distantPast
                    let secondAirDate = second.nextEpisode?.airDateValue ?? .distantPast
                    return firstAirDate > secondAirDate
                }
        } catch {
            errorMessage = error.userFacingMessage
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
                await store.refresh(using: service)
            }
            await fetch()
        } catch {
            errorMessage = error.userFacingMessage
        }
    }
}
