import Foundation
import Testing
@testable import WatchTracker

/// What the app does when the connection is weak or gone, from the ViewModels' side.
///
/// Grouped by behaviour rather than by type because that is how the bugs arrived: "the list
/// vanished", "the tap was lost", "it signed me out" each cut across two or three files.
@MainActor
@Suite("Offline behaviour", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct OfflineBehaviourTests {

    private var offline: APIError { .networkError(URLError(.notConnectedToInternet)) }

    // MARK: - A failed refresh must not take the content away

    @Test func `Home keeps the cached list and shows a banner when a refresh fails`() async {
        let service = MockWatchlistService()
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem()])
        let viewModel = WatchlistViewModel(
            service: service,
            store: store,
            notifications: MockNotificationScheduler()
        )
        service.fetchWatchlistResult = .failure(offline)

        await viewModel.fetchWatchlist(forceRefresh: true)

        #expect(viewModel.allItems.count == 1, "The list the user was reading stays on screen")
        #expect(viewModel.staleMessage == Strings.Common.connectionError)
        #expect(viewModel.errorMessage == nil, "Nothing may take the screen while there is a list")
    }

    @Test func `Home shows a full-screen error when there is nothing cached`() async {
        let service = MockWatchlistService()
        service.fetchWatchlistResult = .failure(offline)
        let viewModel = WatchlistViewModel(
            service: service,
            store: WatchlistStore(),
            notifications: MockNotificationScheduler()
        )

        await viewModel.fetchWatchlist(forceRefresh: true)

        #expect(viewModel.errorMessage == Strings.Common.connectionError)
        #expect(viewModel.staleMessage == nil)
    }

    /// A cache restored from disk after the error was raised makes the error untrue.
    @Test func `syncing from a restored cache clears a blocking error`() async {
        let service = MockWatchlistService()
        service.fetchWatchlistResult = .failure(offline)
        let store = WatchlistStore()
        let viewModel = WatchlistViewModel(
            service: service,
            store: store,
            notifications: MockNotificationScheduler()
        )
        await viewModel.fetchWatchlist(forceRefresh: true)

        store.replace(with: [TestFixtures.watchItem()])
        viewModel.syncFromCache()

        #expect(viewModel.errorMessage == nil)
    }

    @Test func `Continue Watching keeps its rows when a refresh fails`() async {
        let service = MockWatchlistService()
        service.fetchContinueWatchingResult = .success([
            TestFixtures.continueWatchingItem(nextEpisode: TestFixtures.nextEpisode())
        ])
        let viewModel = ContinueWatchingViewModel(
            service: service,
            store: WatchlistStore(),
            outbox: MutationOutbox()
        )
        await viewModel.fetch()

        service.fetchContinueWatchingResult = .failure(offline)
        await viewModel.fetch()

        #expect(viewModel.items.count == 1)
        #expect(viewModel.staleMessage != nil)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - A tap made offline must not be lost

    @Test func `marking an episode offline keeps the checkmark and queues the write`() async {
        let outbox = MutationOutbox()
        let service = MockMediaDetailService()
        let viewModel = await tvViewModel(service: service, outbox: outbox)
        service.markEpisodeWatchedResult = .failure(offline)

        await viewModel.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(viewModel.episodes(inSeason: 1).first?.isWatched == true, "The tap stands")
        #expect(viewModel.actionError == nil, "A queued write is not an error")
        #expect(outbox.pending.first?.kind == .markEpisode(tvId: 5, season: 1, episode: 1, watched: true))
    }

    /// The server answering "no" is the one case where the checkmark must go back.
    @Test func `a rejected episode write reverts and reports`() async {
        let outbox = MutationOutbox()
        let service = MockMediaDetailService()
        let viewModel = await tvViewModel(service: service, outbox: outbox)
        service.markEpisodeWatchedResult = .failure(APIError.serverError)

        await viewModel.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(viewModel.episodes(inSeason: 1).first?.isWatched == false)
        #expect(viewModel.actionError != nil)
        #expect(outbox.isEmpty)
    }

    @Test func `marking a season offline keeps every episode marked and queues one write`() async {
        let outbox = MutationOutbox()
        let service = MockMediaDetailService()
        let viewModel = await tvViewModel(service: service, outbox: outbox)
        service.markSeasonWatchedResult = .failure(offline)

        await viewModel.toggleSeasonWatched(1)

        let everyEpisodeWatched = viewModel.episodes(inSeason: 1).allSatisfy(\.isWatched)
        #expect(everyEpisodeWatched)
        #expect(outbox.pending.first?.kind == .markSeason(tvId: 5, season: 1, watched: true))
    }

    @Test func `rating offline keeps the stars and queues the write`() async {
        let outbox = MutationOutbox()
        let service = MockMediaDetailService()
        service.rateMediaError = offline
        let viewModel = MediaDetailViewModel(
            mediaType: .movie,
            mediaId: 550,
            mediaDetailService: service,
            watchlistService: MockWatchlistService(),
            store: WatchlistStore(),
            outbox: outbox,
            analytics: MockAnalytics()
        )

        await viewModel.rateMedia(rating: 8)

        #expect(viewModel.userRating == 8)
        #expect(outbox.pending.first?.kind == .rate(mediaType: .movie, mediaId: 550, rating: 8))
    }

    @Test func `adding to the watchlist offline shows the status and queues the add`() async {
        let outbox = MutationOutbox()
        let watchlist = MockWatchlistService()
        watchlist.addToWatchlistError = offline
        let viewModel = MediaDetailViewModel(
            mediaType: .movie,
            mediaId: 550,
            mediaDetailService: MockMediaDetailService(),
            watchlistService: watchlist,
            store: WatchlistStore(),
            outbox: outbox,
            analytics: MockAnalytics()
        )

        await viewModel.addToWatchlist(status: .watching)

        #expect(viewModel.watchlistStatus == .watching)
        #expect(viewModel.entry?.isSynced == false, "There is no server id to have")
        #expect(outbox.pending.first?.kind
                == .addToWatchlist(tmdbId: 550, mediaType: .movie, status: .watching))
    }

    /// Undoing an add that never got out is a cancellation, not a second request.
    @Test func `removing a title that was only ever queued drops the queued add`() async {
        let outbox = MutationOutbox()
        let watchlist = MockWatchlistService()
        watchlist.addToWatchlistError = offline
        let viewModel = MediaDetailViewModel(
            mediaType: .movie,
            mediaId: 550,
            mediaDetailService: MockMediaDetailService(),
            watchlistService: watchlist,
            store: WatchlistStore(),
            outbox: outbox,
            analytics: MockAnalytics()
        )
        await viewModel.addToWatchlist(status: .watching)

        await viewModel.removeFromWatchlist()

        #expect(viewModel.entry == nil)
        #expect(outbox.isEmpty)
        #expect(watchlist.removeFromWatchlistCalls.isEmpty, "There is no row to remove")
    }

    @Test func `a queued add is still reflected when the screen is reopened`() async {
        let outbox = MutationOutbox()
        outbox.enqueue(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .planToWatch))
        let viewModel = MediaDetailViewModel(
            mediaType: .movie,
            mediaId: 550,
            mediaDetailService: MockMediaDetailService(),
            watchlistService: MockWatchlistService(),
            store: WatchlistStore(),
            outbox: outbox,
            analytics: MockAnalytics()
        )

        await viewModel.checkWatchlistStatus()

        #expect(viewModel.watchlistStatus == .planToWatch)
    }

    @Test func `marking watched offline from Continue Watching keeps the row gone and queues it`() async {
        let outbox = MutationOutbox()
        let service = MockWatchlistService()
        let item = TestFixtures.continueWatchingItem(nextEpisode: TestFixtures.nextEpisode())
        service.fetchContinueWatchingResult = .success([item])
        let viewModel = ContinueWatchingViewModel(
            service: service,
            store: WatchlistStore(),
            outbox: outbox
        )
        await viewModel.fetch()
        service.markEpisodeWatchedResult = .failure(offline)

        await viewModel.markAsWatched(item)

        #expect(viewModel.items.isEmpty, "The swipe stands")
        #expect(outbox.count == 1)
    }

    @Test func `a rejected mark from Continue Watching puts the row back`() async {
        let outbox = MutationOutbox()
        let service = MockWatchlistService()
        let item = TestFixtures.continueWatchingItem(nextEpisode: TestFixtures.nextEpisode())
        service.fetchContinueWatchingResult = .success([item])
        let viewModel = ContinueWatchingViewModel(
            service: service,
            store: WatchlistStore(),
            outbox: outbox
        )
        await viewModel.fetch()
        service.markEpisodeWatchedResult = .failure(APIError.serverError)

        await viewModel.markAsWatched(item)

        #expect(viewModel.items.count == 1)
        #expect(outbox.isEmpty)
    }

    // MARK: - Helpers

    /// A TV view model with season 1 loaded and unwatched, which is the state every
    /// episode-marking test starts from.
    private func tvViewModel(
        service: MockMediaDetailService,
        outbox: MutationOutbox
    ) async -> MediaDetailViewModel {
        service.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        service.fetchSeasonDetailResult = .success(
            TestFixtures.season(seasonNumber: 1, episodes: [
                TestFixtures.episode(episodeNumber: 1),
                TestFixtures.episode(id: 2, episodeNumber: 2),
            ])
        )
        service.fetchWatchedEpisodesResult = .success([])

        let viewModel = MediaDetailViewModel(
            mediaType: .tv,
            mediaId: 5,
            mediaDetailService: service,
            watchlistService: MockWatchlistService(),
            store: WatchlistStore(),
            outbox: outbox,
            analytics: MockAnalytics()
        )
        await viewModel.loadSeasonIfNeeded(1)
        return viewModel
    }
}
