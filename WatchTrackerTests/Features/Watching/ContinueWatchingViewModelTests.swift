import Testing
@testable import WatchTracker

@Suite(.tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct ContinueWatchingViewModelTests {

    // MARK: - fetch filtering

    @Test func `fetch includes items where next episode is released`() async {
        let releasedEpisode = TestFixtures.nextEpisode(airDate: TestFixtures.yesterdayDateString())
        let item = TestFixtures.continueWatchingItem(nextEpisode: releasedEpisode)
        let mock = MockWatchlistService()
        mock.fetchContinueWatchingResult = .success([item])
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.fetch()
        #expect(vm.items.count == 1)
    }

    @Test func `fetch excludes items where next episode is not yet released`() async {
        let futureEpisode = TestFixtures.nextEpisode(airDate: TestFixtures.tomorrowDateString())
        let item = TestFixtures.continueWatchingItem(nextEpisode: futureEpisode)
        let mock = MockWatchlistService()
        mock.fetchContinueWatchingResult = .success([item])
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.fetch()
        #expect(vm.items.isEmpty, "Items with unreleased episodes should be filtered out")
    }

    @Test func `fetch includes items with no next episode`() async {
        let item = TestFixtures.continueWatchingItem(nextEpisode: nil)
        let mock = MockWatchlistService()
        mock.fetchContinueWatchingResult = .success([item])
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.fetch()
        #expect(vm.items.count == 1)
    }

    @Test func `fetch sets errorMessage on failure`() async {
        let mock = MockWatchlistService()
        mock.fetchContinueWatchingResult = .failure(MockError.generic("network error"))
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.fetch()
        #expect(vm.errorMessage != nil)
        #expect(vm.items.isEmpty)
    }

    @Test func `isLoading is false after fetch`() async {
        let mock = MockWatchlistService()
        mock.fetchContinueWatchingResult = .success([])
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.fetch()
        #expect(vm.isLoading == false)
    }

    // MARK: - markAsWatched

    @Test func `markAsWatched does nothing when item has no next episode`() async {
        let mock = MockWatchlistService()
        let item = TestFixtures.continueWatchingItem(nextEpisode: nil)
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.markAsWatched(item)
        #expect(mock.markEpisodeWatchedCalls.isEmpty)
    }

    @Test func `markAsWatched calls service with correct parameters`() async {
        let episode = TestFixtures.nextEpisode(seasonNumber: 2, episodeNumber: 5)
        let item = TestFixtures.continueWatchingItem(tmdbId: 99, nextEpisode: episode)
        let mock = MockWatchlistService()
        mock.fetchContinueWatchingResult = .success([])
        await vm_markAsWatched(item: item, mock: mock)
        let call = try! #require(mock.markEpisodeWatchedCalls.first)
        #expect(call.tvId == 99)
        #expect(call.season == 2)
        #expect(call.episode == 5)
    }

    @Test func `markAsWatched does not refresh watchlist when status unchanged`() async {
        let episode = TestFixtures.nextEpisode()
        let item = TestFixtures.continueWatchingItem(nextEpisode: episode)
        let mock = MockWatchlistService()
        mock.markEpisodeWatchedResult = .success(nil)  // no status change
        mock.fetchContinueWatchingResult = .success([])
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.markAsWatched(item)
        // fetchWatchlist should NOT have been called (only fetchContinueWatching for re-fetch)
        #expect(mock.fetchWatchlistCallCount == 0)
    }

    @Test func `markAsWatched refreshes watchlist cache when status changes`() async {
        let episode = TestFixtures.nextEpisode()
        let item = TestFixtures.continueWatchingItem(nextEpisode: episode)
        let mock = MockWatchlistService()
        mock.markEpisodeWatchedResult = .success(.completed)  // status changed
        mock.fetchWatchlistResult = .success([])
        mock.fetchContinueWatchingResult = .success([])
        let store = WatchlistStore()
        let vm = ContinueWatchingViewModel(service: mock, store: store)
        await vm.markAsWatched(item)
        #expect(mock.fetchWatchlistCallCount == 1, "Should refresh cache when status changes")
    }

    @Test func `markAsWatched re-fetches items after marking watched`() async {
        let episode = TestFixtures.nextEpisode()
        let item = TestFixtures.continueWatchingItem(nextEpisode: episode)
        let mock = MockWatchlistService()
        mock.markEpisodeWatchedResult = .success(nil)
        mock.fetchContinueWatchingResult = .success([])
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.markAsWatched(item)
        #expect(mock.fetchContinueWatchingCallCount >= 1)
    }

    @Test func `markAsWatched sets errorMessage on service failure`() async {
        let episode = TestFixtures.nextEpisode()
        let item = TestFixtures.continueWatchingItem(nextEpisode: episode)
        let mock = MockWatchlistService()
        mock.markEpisodeWatchedResult = .failure(MockError.generic("error"))
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.markAsWatched(item)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Helpers

    private func vm_markAsWatched(item: ContinueWatchingItem, mock: MockWatchlistService) async {
        mock.fetchContinueWatchingResult = .success([])
        let vm = ContinueWatchingViewModel(service: mock)
        await vm.markAsWatched(item)
    }
}
