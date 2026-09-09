import Foundation

/// A write the user made that never reached the backend.
nonisolated struct PendingMutation: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    let kind: Kind

    enum Kind: Codable, Equatable, Sendable {
        case markEpisode(tvId: Int, season: Int, episode: Int, watched: Bool)
        case markSeason(tvId: Int, season: Int, watched: Bool)
        case addToWatchlist(tmdbId: Int, mediaType: MediaType, status: WatchlistStatus)
        case updateStatus(entryId: Int, status: WatchlistStatus)
        case removeFromWatchlist(entryId: Int)
        /// `rating` is `nil` for "remove my rating".
        case rate(mediaType: MediaType, mediaId: Int, rating: Int?)
    }

    /// What this write is *about*. Two queued writes with the same target are two versions of
    /// one decision — marking an episode, then unmarking it — so only the newer needs sending.
    var target: String {
        switch kind {
        case let .markEpisode(tvId, season, episode, _):
            return "episode:\(tvId):\(season):\(episode)"
        case let .markSeason(tvId, season, _):
            return "season:\(tvId):\(season)"
        case let .addToWatchlist(tmdbId, mediaType, _):
            return "watchlist:\(mediaType.rawValue):\(tmdbId)"
        case let .updateStatus(entryId, _), let .removeFromWatchlist(entryId):
            return "entry:\(entryId)"
        case let .rate(mediaType, mediaId, _):
            return "rating:\(mediaType.rawValue):\(mediaId)"
        }
    }
}

/// The writes that are waiting for a connection, in the order they were made.
///
/// Marking an episode on a train should not be a coin flip. When a write fails because the
/// request never left the device, the UI keeps the change the user made and it lands here
/// instead of being rolled back; `drain` replays the queue when connectivity returns.
///
/// Deliberately narrow: only the small, idempotent watchlist writes go through it. Anything
/// whose result the user is waiting to *read* — a search, a detail load, an import — has no
/// business being queued.
@Observable
@MainActor
final class MutationOutbox {
    /// What one `drain` did, so the caller can decide whether the rest of the app needs a refresh.
    struct DrainResult: Equatable {
        var applied: Int = 0
        var discarded: Int = 0
        /// `true` when the drain stopped early because the connection went away again.
        var stoppedOffline: Bool = false

        var changedAnything: Bool { applied > 0 }
    }

    private(set) var pending: [PendingMutation] = []

    /// Guards against two drains at once. They are triggered by whatever happens to change —
    /// a reconnect, a foregrounding, a write that just failed — and those can coincide, which
    /// without this would send the same queued write twice.
    private var isDraining = false

    private let archive: any FileArchiving<[PendingMutation]>
    private let now: @Sendable () -> Date

    init(
        archive: any FileArchiving<[PendingMutation]> = InMemoryArchive(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.archive = archive
        self.now = now
        pending = archive.load() ?? []
    }

    var isEmpty: Bool { pending.isEmpty }
    var count: Int { pending.count }

    /// Records a write to replay later, replacing any earlier one about the same thing.
    ///
    /// Replacing rather than appending is what keeps a user who toggles the same episode four
    /// times offline from sending four requests — and from sending them in an order that could
    /// land on the wrong final state.
    func enqueue(_ kind: PendingMutation.Kind) {
        let mutation = PendingMutation(id: UUID(), createdAt: now(), kind: kind)
        pending.removeAll { $0.target == mutation.target }
        pending.append(mutation)
        persist()
    }

    /// Drops a queued write without sending it — for when the user undoes it before it ever
    /// got out, which makes both writes unnecessary rather than one of them wrong.
    func cancel(_ kind: PendingMutation.Kind) {
        let target = PendingMutation(id: UUID(), createdAt: now(), kind: kind).target
        pending.removeAll { $0.target == target }
        persist()
    }

    /// Drops everything. Sign-out only: these are the previous user's changes.
    func clear() {
        pending = []
        persist()
    }

    /// The queued write that will change this title's watchlist row, newest first, if any.
    ///
    /// Returned raw for the caller to interpret: what "an add is queued" means for a screen
    /// is the screen's business, and this type has no opinion about presentation.
    func pendingWatchlistChange(
        tmdbId: Int,
        mediaType: MediaType,
        entryId: Int?
    ) -> PendingMutation.Kind? {
        pending.reversed().first { mutation in
            switch mutation.kind {
            case let .addToWatchlist(queuedId, queuedType, _):
                return queuedId == tmdbId && queuedType == mediaType
            case let .updateStatus(queuedEntryId, _), let .removeFromWatchlist(queuedEntryId):
                return entryId != nil && queuedEntryId == entryId
            default:
                return false
            }
        }?.kind
    }

    /// Replays the queue oldest-first.
    ///
    /// Two failure policies, and the difference matters. A write that fails on connectivity
    /// stays queued and stops the drain — the rest would only fail the same way. A write the
    /// server *answered* and refused (the row is gone, the title is not on the watchlist any
    /// more) is discarded: it will be refused identically forever, and a queue that cannot
    /// empty is a queue that blocks every write behind it.
    @discardableResult
    func drain(
        watchlist: any WatchlistServiceProtocol,
        mediaDetail: any MediaDetailServiceProtocol
    ) async -> DrainResult {
        guard !isDraining else { return DrainResult() }
        isDraining = true
        defer { isDraining = false }

        var result = DrainResult()

        while let mutation = pending.first {
            do {
                try await apply(mutation, watchlist: watchlist, mediaDetail: mediaDetail)
                pending.removeFirst()
                result.applied += 1
            } catch where error.isConnectivityFailure {
                result.stoppedOffline = true
                break
            } catch {
                pending.removeFirst()
                result.discarded += 1
            }
            persist()
        }

        persist()
        return result
    }

    // MARK: - Private

    private func apply(
        _ mutation: PendingMutation,
        watchlist: any WatchlistServiceProtocol,
        mediaDetail: any MediaDetailServiceProtocol
    ) async throws {
        switch mutation.kind {
        case let .markEpisode(tvId, season, episode, watched):
            _ = watched
                ? try await mediaDetail.markEpisodeWatched(tvId: tvId, season: season, episode: episode)
                : try await mediaDetail.unmarkEpisodeWatched(tvId: tvId, season: season, episode: episode)
        case let .markSeason(tvId, season, watched):
            _ = watched
                ? try await mediaDetail.markSeasonWatched(tvId: tvId, season: season)
                : try await mediaDetail.unmarkSeasonWatched(tvId: tvId, season: season)
        case let .addToWatchlist(tmdbId, mediaType, status):
            try await watchlist.addToWatchlist(tmdbId: tmdbId, mediaType: mediaType, status: status)
        case let .updateStatus(entryId, status):
            try await watchlist.updateStatus(id: entryId, status: status)
        case let .removeFromWatchlist(entryId):
            try await watchlist.removeFromWatchlist(id: entryId)
        case let .rate(mediaType, mediaId, rating):
            if let rating {
                try await mediaDetail.rateMedia(type: mediaType, id: mediaId, rating: rating)
            } else {
                try await mediaDetail.removeRating(type: mediaType, id: mediaId)
            }
        }
    }

    private func persist() {
        archive.save(pending)
    }
}
