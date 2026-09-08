import Testing
@testable import WatchTracker

/// Every write on the detail screen is a round trip, and the UI now shows a spinner and
/// locks the control while one is out. These cover the state that drives it: it is set
/// during the call, cleared afterwards (success *and* failure), and blocks a second tap.
@MainActor
@Suite("Detail write actions expose in-flight state", .tags(.viewModel), .timeLimit(.minutes(1)))
struct MediaDetailViewModelPendingTests {

    private func makeVM(
        _ service: MockMediaDetailService,
        watchlistService: MockWatchlistService? = nil
    ) -> MediaDetailViewModel {
        MediaDetailViewModel(
            mediaDetailService: service,
            watchlistService: watchlistService ?? MockWatchlistService(),
            store: WatchlistStore()
        )
    }

    /// The ViewModel only routes episode writes for TV, so every case has to load a show first.
    private func makeTVVM(_ service: MockMediaDetailService) async -> MediaDetailViewModel {
        service.fetchMediaDetailResult = .success(TestFixtures.tvDetail(seasons: [(1, 2)]))
        let vm = makeVM(service)
        await vm.fetchDetails(type: .tv, id: 2)
        vm.seasonEpisodes[1] = [
            TestFixtures.episode(episodeNumber: 1, isWatched: false),
            TestFixtures.episode(id: 2, episodeNumber: 2, isWatched: false)
        ]
        return vm
    }

    // MARK: - Episodes

    @Test func `episode is pending while its mark request is in flight`() async {
        let service = MockMediaDetailService()
        let vm = await makeTVVM(service)

        var pendingDuringCall: Bool?
        service.duringCall = { pendingDuringCall = vm.isEpisodePending(season: 1, episode: 1) }

        await vm.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(pendingDuringCall == true)
        #expect(vm.isEpisodePending(season: 1, episode: 1) == false)
    }

    @Test func `only the tapped episode is pending`() async {
        let service = MockMediaDetailService()
        let vm = await makeTVVM(service)

        var otherPending: Bool?
        service.duringCall = { otherPending = vm.isEpisodePending(season: 1, episode: 2) }

        await vm.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(otherPending == false)
    }

    @Test func `episode stops being pending when the request fails`() async {
        let service = MockMediaDetailService()
        let vm = await makeTVVM(service)
        service.markEpisodeWatchedResult = .failure(MockError.generic("offline"))

        await vm.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(vm.pendingEpisodes.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    /// Tapping a row twice before the server answers would otherwise send a mark *and*
    /// an unmark, leaving the row showing the opposite of what the server stored.
    @Test func `a second tap is dropped while the first is still in flight`() async {
        let service = MockMediaDetailService()
        let vm = await makeTVVM(service)

        var reentrantCallCount = 0
        service.duringCall = {
            guard reentrantCallCount == 0 else { return }
            reentrantCallCount += 1
            Task { await vm.toggleEpisodeWatched(season: 1, episode: 1) }
        }

        await vm.toggleEpisodeWatched(season: 1, episode: 1)
        // Let the re-entrant task run — it must bail on the guard, not reach the service.
        await Task.yield()

        #expect(service.markEpisodeWatchedCalls.count == 1)
    }

    // MARK: - Seasons

    @Test func `season is pending while its mark-all request is in flight`() async {
        let service = MockMediaDetailService()
        let vm = await makeTVVM(service)

        var pendingDuringCall: Bool?
        service.duringCall = { pendingDuringCall = vm.pendingSeasons.contains(1) }

        await vm.toggleSeasonWatched(1)

        #expect(pendingDuringCall == true)
        #expect(vm.pendingSeasons.isEmpty)
    }

    @Test func `season stops being pending when the request fails`() async {
        let service = MockMediaDetailService()
        let vm = await makeTVVM(service)
        service.markSeasonWatchedResult = .failure(MockError.generic("offline"))

        await vm.toggleSeasonWatched(1)

        #expect(vm.pendingSeasons.isEmpty)
    }

    // MARK: - Rating

    @Test func `rating is submitting while the request is in flight`() async {
        let service = MockMediaDetailService()
        let vm = makeVM(service)
        await vm.fetchDetails(type: .movie, id: 1)

        var submittingDuringCall: Bool?
        service.duringCall = { submittingDuringCall = vm.isSubmittingRating }

        await vm.rateMedia(rating: 8)

        #expect(submittingDuringCall == true)
        #expect(vm.isSubmittingRating == false)
    }

    @Test func `removing a rating is submitting while the request is in flight`() async {
        let service = MockMediaDetailService()
        let vm = makeVM(service)
        await vm.fetchDetails(type: .movie, id: 1)

        var submittingDuringCall: Bool?
        service.duringCall = { submittingDuringCall = vm.isSubmittingRating }

        await vm.removeRating()

        #expect(submittingDuringCall == true)
        #expect(vm.isSubmittingRating == false)
    }

    @Test func `rating stops submitting when the request fails`() async {
        let service = MockMediaDetailService()
        service.rateMediaError = MockError.generic("offline")
        let vm = makeVM(service)
        await vm.fetchDetails(type: .movie, id: 1)

        await vm.rateMedia(rating: 8)

        #expect(vm.isSubmittingRating == false)
        #expect(vm.userRating == nil)
    }

    // MARK: - Watchlist

    @Test func `removing from the watchlist reports an in-flight status change`() async {
        let service = MockMediaDetailService()
        let watchlist = MockWatchlistService()
        let vm = makeVM(service, watchlistService: watchlist)
        await vm.fetchDetails(type: .movie, id: 1)
        vm.watchlistItemId = 42
        vm.isOnWatchlist = true

        var updatingDuringCall: Bool?
        watchlist.duringRemove = { updatingDuringCall = vm.isUpdatingStatus }

        await vm.removeFromWatchlist()

        #expect(updatingDuringCall == true)
        #expect(vm.isUpdatingStatus == false)
        #expect(vm.isOnWatchlist == false)
    }
}
