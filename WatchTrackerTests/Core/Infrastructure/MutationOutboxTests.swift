import Foundation
import Testing
@testable import WatchTracker

@MainActor
@Suite("MutationOutbox", .tags(.service, .async), .timeLimit(.minutes(1)))
struct MutationOutboxTests {

    private func outbox(
        _ archive: InMemoryArchive<[PendingMutation]> = InMemoryArchive()
    ) -> MutationOutbox {
        MutationOutbox(archive: archive)
    }

    private let offline = APIError.networkError(URLError(.notConnectedToInternet))

    // MARK: - Queueing

    @Test func `enqueue keeps writes in the order they were made`() {
        let outbox = outbox()

        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 1, watched: true))
        outbox.enqueue(.rate(mediaType: .movie, mediaId: 550, rating: 8))

        #expect(outbox.count == 2)
        #expect(outbox.pending.first?.kind == .markEpisode(tvId: 1, season: 1, episode: 1, watched: true))
    }

    /// Toggling the same episode four times offline is one decision, not four requests.
    @Test func `enqueue replaces an earlier write about the same thing`() {
        let outbox = outbox()

        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 1, watched: true))
        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 1, watched: false))

        #expect(outbox.count == 1)
        #expect(outbox.pending.first?.kind == .markEpisode(tvId: 1, season: 1, episode: 1, watched: false))
    }

    @Test func `enqueue keeps writes about different episodes apart`() {
        let outbox = outbox()

        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 1, watched: true))
        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 2, watched: true))

        #expect(outbox.count == 2)
    }

    @Test func `cancel drops a queued write without sending it`() {
        let outbox = outbox()
        outbox.enqueue(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .planToWatch))

        outbox.cancel(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .watching))

        #expect(outbox.isEmpty)
    }

    // MARK: - Persistence

    @Test func `queued writes survive a relaunch`() {
        let archive = InMemoryArchive<[PendingMutation]>()
        outbox(archive).enqueue(.rate(mediaType: .tv, mediaId: 1396, rating: 10))

        let relaunched = outbox(archive)

        #expect(relaunched.count == 1)
    }

    @Test func `clear empties the archive too`() {
        let archive = InMemoryArchive<[PendingMutation]>()
        let queue = outbox(archive)
        queue.enqueue(.rate(mediaType: .tv, mediaId: 1396, rating: 10))

        queue.clear()

        #expect(outbox(archive).isEmpty)
    }

    // MARK: - Draining

    @Test func `drain sends every queued write and empties`() async {
        let outbox = outbox()
        let watchlist = MockWatchlistService()
        let mediaDetail = MockMediaDetailService()
        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 1, watched: true))
        outbox.enqueue(.rate(mediaType: .movie, mediaId: 550, rating: 8))

        let result = await outbox.drain(watchlist: watchlist, mediaDetail: mediaDetail)

        #expect(result.applied == 2)
        #expect(result.stoppedOffline == false)
        #expect(outbox.isEmpty)
    }

    @Test func `drain keeps everything when the connection is still gone`() async {
        let outbox = outbox()
        let mediaDetail = MockMediaDetailService()
        mediaDetail.markEpisodeWatchedResult = .failure(offline)
        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 1, watched: true))
        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 2, watched: true))

        let result = await outbox.drain(watchlist: MockWatchlistService(), mediaDetail: mediaDetail)

        #expect(result.applied == 0)
        #expect(result.stoppedOffline)
        #expect(outbox.count == 2, "Nothing is dropped, and the drain stops rather than failing the rest")
    }

    /// A write the server answered and refused will be refused identically forever. Keeping
    /// it would block every write queued behind it.
    @Test func `drain discards a write the server rejected`() async {
        let outbox = outbox()
        let mediaDetail = MockMediaDetailService()
        mediaDetail.markEpisodeWatchedResult = .failure(APIError.notFound)
        outbox.enqueue(.markEpisode(tvId: 1, season: 1, episode: 1, watched: true))

        let result = await outbox.drain(watchlist: MockWatchlistService(), mediaDetail: mediaDetail)

        #expect(result.discarded == 1)
        #expect(outbox.isEmpty)
    }

    @Test func `drain leaves the archive empty after a successful replay`() async {
        let archive = InMemoryArchive<[PendingMutation]>()
        let queue = outbox(archive)
        queue.enqueue(.rate(mediaType: .movie, mediaId: 550, rating: 8))

        await queue.drain(watchlist: MockWatchlistService(), mediaDetail: MockMediaDetailService())

        #expect(outbox(archive).isEmpty)
    }

    /// A reconnect, a foregrounding and a write that just failed can all ask for a drain at
    /// once. Without the guard, the same queued write goes out twice.
    @Test func `a drain that starts while one is running does nothing`() async {
        let queue = outbox()
        let watchlist = MockWatchlistService()
        let mediaDetail = MockMediaDetailService()
        queue.enqueue(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .watching))
        watchlist.duringAdd = { [queue] in
            await queue.drain(watchlist: watchlist, mediaDetail: mediaDetail)
        }

        await queue.drain(watchlist: watchlist, mediaDetail: mediaDetail)

        #expect(watchlist.addToWatchlistCalls.count == 1)
        #expect(queue.isEmpty)
    }

    @Test func `unmarking replays as an unmark, not a mark`() async {
        let outbox = outbox()
        let mediaDetail = MockMediaDetailService()
        outbox.enqueue(.markEpisode(tvId: 1, season: 2, episode: 3, watched: false))

        await outbox.drain(watchlist: MockWatchlistService(), mediaDetail: mediaDetail)

        #expect(mediaDetail.unmarkEpisodeWatchedCalls.count == 1)
        #expect(mediaDetail.markEpisodeWatchedCalls.isEmpty)
    }

    @Test func `a nil rating replays as removing the rating`() async {
        let outbox = outbox()
        let mediaDetail = MockMediaDetailService()
        outbox.enqueue(.rate(mediaType: .movie, mediaId: 550, rating: nil))

        await outbox.drain(watchlist: MockWatchlistService(), mediaDetail: mediaDetail)

        #expect(mediaDetail.removeRatingCalls.count == 1)
    }

    // MARK: - Queries

    @Test func `pendingWatchlistChange finds a queued add by TMDB id`() {
        let outbox = outbox()
        outbox.enqueue(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .watching))

        let queued = outbox.pendingWatchlistChange(tmdbId: 550, mediaType: .movie, entryId: nil)

        #expect(queued == .addToWatchlist(tmdbId: 550, mediaType: .movie, status: .watching))
    }

    @Test func `pendingWatchlistChange ignores another title`() {
        let outbox = outbox()
        outbox.enqueue(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .watching))

        #expect(outbox.pendingWatchlistChange(tmdbId: 551, mediaType: .movie, entryId: nil) == nil)
    }

    @Test func `pendingWatchlistChange finds a queued removal by entry id`() {
        let outbox = outbox()
        outbox.enqueue(.removeFromWatchlist(entryId: 7))

        #expect(outbox.pendingWatchlistChange(tmdbId: 550, mediaType: .movie, entryId: 7)
                == .removeFromWatchlist(entryId: 7))
    }

    @Test func `pendingWatchlistChange ignores episode writes`() {
        let outbox = outbox()
        outbox.enqueue(.markEpisode(tvId: 550, season: 1, episode: 1, watched: true))

        #expect(outbox.pendingWatchlistChange(tmdbId: 550, mediaType: .tv, entryId: nil) == nil)
    }
}
