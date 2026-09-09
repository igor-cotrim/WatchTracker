import Foundation

@Observable
@MainActor
final class ContinueWatchingViewModel {
    private(set) var items: [ContinueWatchingItem] = []
    private(set) var isLoading = false

    /// Why the list is not what the user expects — a load that failed, or a write the server
    /// refused — and whether that costs the whole screen or just a line above the rows that
    /// are already there. A write never takes the screen: the rows around it are still right.
    private(set) var failure: LoadFailure?

    var errorMessage: String? { failure?.isBlocking == true ? failure?.message : nil }
    var staleMessage: String? { failure?.isBlocking == false ? failure?.message : nil }

    private let service: WatchlistServiceProtocol
    private let store: WatchlistStore
    private let outbox: MutationOutbox

    init(
        service: WatchlistServiceProtocol,
        store: WatchlistStore,
        outbox: MutationOutbox
    ) {
        self.service = service
        self.store = store
        self.outbox = outbox
    }

    func fetch() async {
        isLoading = true
        failure = nil
        do {
            items = try await service.fetchContinueWatching()
                .filter { $0.nextEpisode?.isReleased != false }
                .sorted { first, second in
                    let firstAirDate = first.nextEpisode?.airDateValue ?? .distantPast
                    let secondAirDate = second.nextEpisode?.airDateValue ?? .distantPast
                    return firstAirDate > secondAirDate
                }
        } catch {
            failure = .from(error, hasContent: !items.isEmpty)
        }
        isLoading = false
    }

    /// Marks the next episode watched, optimistically.
    ///
    /// The row leaves the list the moment the user swipes, because that is what they just
    /// said happened. If the request cannot go out, the change is queued rather than undone —
    /// a row that reappears under your thumb on the train reads as the app losing the tap.
    func markAsWatched(_ item: ContinueWatchingItem) async {
        guard let next = item.nextEpisode else { return }

        let previousItems = items
        items.removeAll { $0.id == item.id }

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
        } catch where error.isConnectivityFailure {
            outbox.enqueue(.markEpisode(
                tvId: item.tmdbId,
                season: next.seasonNumber,
                episode: next.episodeNumber,
                watched: true
            ))
            // The row stays gone — the next episode of this show is not known offline, so it
            // comes back with the next successful fetch rather than being guessed at. No
            // notice here: the app-wide offline banner already says changes will sync, and it
            // clears itself when they do, which a message stored on this screen could not.
        } catch {
            // The server answered and refused: put the row back, it was never watched.
            items = previousItems
            failure = .stale(error.userFacingMessage)
        }
    }
}
