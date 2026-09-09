import Testing
@testable import WatchTracker

@MainActor
@Suite(.tags(.viewModel), .timeLimit(.minutes(1)))
struct MediaDetailViewModelTests {

    /// The title is identity now, so it is fixed at construction rather than passed to
    /// whichever fetch runs first. `id: 1` matches the `tmdbId` the fixtures use below.
    private func makeVM(
        type: MediaType = .movie,
        id: Int = 1,
        mediaDetailService: MockMediaDetailService? = nil,
        watchlistService: MockWatchlistService? = nil,
        store: WatchlistStore? = nil
    ) -> MediaDetailViewModel {
        MediaDetailViewModel(
            mediaType: type,
            mediaId: id,
            mediaDetailService: mediaDetailService ?? MockMediaDetailService(),
            watchlistService: watchlistService ?? MockWatchlistService(),
            store: store ?? WatchlistStore(),
            analytics: MockAnalytics()
        )
    }

    /// A TV view model whose season 1 is loaded, through the mock rather than by writing
    /// onto the view model.
    private func tvVM(
        _ service: MockMediaDetailService,
        id: Int = 5,
        episodes: [Episode],
        watched: [Int] = [],
        watchlistService: MockWatchlistService? = nil,
        store: WatchlistStore? = nil
    ) async -> MediaDetailViewModel {
        service.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: id))
        service.fetchSeasonDetailResult = .success(TestFixtures.season(seasonNumber: 1, episodes: episodes))
        service.fetchWatchedEpisodesResult = .success(watched)
        let vm = makeVM(
            type: .tv,
            id: id,
            mediaDetailService: service,
            watchlistService: watchlistService,
            store: store
        )
        await vm.fetchDetails()
        await vm.loadSeasonIfNeeded(1)
        return vm
    }

    private func episodes(_ count: Int) -> [Episode] {
        (1...count).map { TestFixtures.episode(id: $0, episodeNumber: $0) }
    }

    // MARK: - toggleExpanded (pure, synchronous)

    @Test func `toggleExpanded adds season to expanded set`() {
        let vm = makeVM()
        vm.toggleExpanded(1)
        #expect(vm.expandedSeasons.contains(1))
    }

    @Test func `toggleExpanded twice removes season from expanded set`() {
        let vm = makeVM()
        vm.toggleExpanded(1)
        vm.toggleExpanded(1)
        #expect(vm.expandedSeasons.contains(1) == false)
    }

    @Test func `toggleExpanded different seasons are independent`() {
        let vm = makeVM()
        vm.toggleExpanded(1)
        vm.toggleExpanded(2)
        #expect(vm.expandedSeasons.contains(1))
        #expect(vm.expandedSeasons.contains(2))
    }

    // MARK: - isSeasonAllWatched

    @Test func `isSeasonAllWatched returns false when the season is not loaded`() {
        #expect(makeVM().isSeasonAllWatched(1) == false)
    }

    @Test func `isSeasonAllWatched returns false for a season with no episodes`() async {
        let vm = await tvVM(MockMediaDetailService(), episodes: [])
        #expect(vm.isSeasonAllWatched(1) == false)
    }

    @Test(arguments: [0, 1, 2, 3])
    func `isSeasonAllWatched for varying watch counts out of 3`(watchedCount: Int) async {
        let vm = await tvVM(
            MockMediaDetailService(),
            episodes: episodes(3),
            watched: Array(1...3).filter { $0 <= watchedCount }
        )
        #expect(vm.isSeasonAllWatched(1) == (watchedCount == 3))
    }

    // MARK: - checkWatchlistStatus (reads from the injected store)

    @Test func `checkWatchlistStatus leaves no entry when the store is empty`() async {
        let vm = makeVM(store: WatchlistStore())
        await vm.checkWatchlistStatus()
        #expect(vm.entry == nil)
        #expect(vm.isOnWatchlist == false)
        #expect(vm.watchlistStatus == nil)
    }

    @Test func `checkWatchlistStatus finds the matching item in the store`() async {
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem(id: 5, tmdbId: 1, mediaType: .movie, status: .watching)])
        let vm = makeVM(store: store)
        await vm.checkWatchlistStatus()
        #expect(vm.entry == WatchlistEntry(id: 5, status: .watching))
        #expect(vm.isOnWatchlist)
    }

    @Test func `checkWatchlistStatus ignores an item of the wrong media type`() async {
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem(tmdbId: 1, mediaType: .tv)])
        let vm = makeVM(store: store)
        await vm.checkWatchlistStatus()
        #expect(vm.entry == nil)
    }

    @Test func `checkWatchlistStatus resets isCheckingStatus via defer`() async {
        let vm = makeVM()
        await vm.checkWatchlistStatus()
        #expect(vm.isCheckingStatus == false)
    }

    /// Legacy data created before the DB unique constraint: several rows for the same
    /// (tmdbId, mediaType). The latest row wins.
    @Test func `the entry picks the latest id when duplicates exist`() async {
        let store = WatchlistStore()
        store.replace(with: [
            TestFixtures.watchItem(id: 10, tmdbId: 1, mediaType: .movie, status: .watching),
            TestFixtures.watchItem(id: 25, tmdbId: 1, mediaType: .movie, status: .completed),
            TestFixtures.watchItem(id: 17, tmdbId: 1, mediaType: .movie, status: .planToWatch),
        ])
        let vm = makeVM(store: store)
        await vm.checkWatchlistStatus()
        #expect(vm.entry == WatchlistEntry(id: 25, status: .completed))
    }

    // MARK: - fetchDetails

    @Test func `fetchDetails loads the title`() async {
        let mock = MockMediaDetailService()
        mock.fetchMediaDetailResult = .success(TestFixtures.mediaDetail(id: 42))
        let vm = makeVM(id: 42, mediaDetailService: mock)

        await vm.fetchDetails()

        guard case .loaded(let media) = vm.state else {
            return #expect(Bool(false), "expected .loaded")
        }
        #expect(media.id == 42)
    }

    @Test func `fetchDetails fails into the state with nothing to show`() async {
        let mock = MockMediaDetailService()
        mock.fetchMediaDetailResult = .failure(MockError.generic("not found"))
        let vm = makeVM(mediaDetailService: mock)

        await vm.fetchDetails()

        guard case .failed = vm.state else { return #expect(Bool(false), "expected .failed") }
        #expect(vm.media == nil)
    }

    @Test func `fetchDetails detects a watchlistStatus change after the initial load`() async {
        let mock = MockMediaDetailService()
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem(id: 3, tmdbId: 1, mediaType: .movie, status: .watching)])

        mock.fetchMediaDetailResult = .success(TestFixtures.mediaDetail(watchlistStatus: .watching))
        let vm = makeVM(mediaDetailService: mock, store: store)
        await vm.fetchDetails()
        await vm.checkWatchlistStatus()  // sets hasLoadedInitialStatus = true

        mock.fetchMediaDetailResult = .success(TestFixtures.mediaDetail(watchlistStatus: .completed))
        await vm.fetchDetails()

        #expect(vm.watchlistStatus == .completed)
        #expect(vm.entry?.id == 3, "the row id survives a status-only change")
        #expect(store.needsRefresh)
    }

    // MARK: - addToWatchlist

    @Test func `addToWatchlist does not mark all episodes for a movie`() async {
        let watchlistMock = MockWatchlistService()
        let vm = makeVM(watchlistService: watchlistMock)
        await vm.addToWatchlist(status: .completed)
        #expect(watchlistMock.markAllEpisodesWatchedCalls.isEmpty)
    }

    @Test func `addToWatchlist marks all episodes for a completed show`() async {
        let watchlistMock = MockWatchlistService()
        let vm = await tvVM(MockMediaDetailService(), episodes: episodes(2), watchlistService: watchlistMock)
        await vm.addToWatchlist(status: .completed)
        #expect(watchlistMock.markAllEpisodesWatchedCalls.isEmpty == false)
        #expect(vm.episodes(inSeason: 1).allSatisfy { $0.isWatched })
    }

    @Test func `addToWatchlist does not mark all episodes for a show still in progress`() async {
        let watchlistMock = MockWatchlistService()
        let vm = await tvVM(MockMediaDetailService(), episodes: episodes(2), watchlistService: watchlistMock)
        await vm.addToWatchlist(status: .watching)
        #expect(watchlistMock.markAllEpisodesWatchedCalls.isEmpty)
    }

    @Test func `addToWatchlist routes to updateStatus when the title is already on the list`() async {
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([
            TestFixtures.watchItem(id: 42, tmdbId: 1, mediaType: .movie, status: .completed)
        ])
        let store = WatchlistStore()
        store.replace(with: [
            TestFixtures.watchItem(id: 42, tmdbId: 1, mediaType: .movie, status: .watching)
        ])
        let vm = makeVM(watchlistService: watchlistMock, store: store)
        await vm.checkWatchlistStatus()

        await vm.addToWatchlist(status: .completed)

        #expect(watchlistMock.updateStatusCalls.first?.id == 42)
        #expect(watchlistMock.updateStatusCalls.first?.status == .completed)
        #expect(watchlistMock.addToWatchlistCalls.isEmpty)
    }

    /// A write that fails leaves the screen showing the title — only the alert changes.
    @Test func `a failed watchlist write does not take the screen down`() async {
        let mediaMock = MockMediaDetailService()
        let watchlistMock = MockWatchlistService()
        watchlistMock.addToWatchlistError = MockError.generic("offline")
        let vm = makeVM(mediaDetailService: mediaMock, watchlistService: watchlistMock)
        await vm.fetchDetails()

        await vm.addToWatchlist(status: .watching)

        #expect(vm.actionError != nil)
        guard case .loaded = vm.state else { return #expect(Bool(false), "expected .loaded") }
    }

    // MARK: - removeFromWatchlist

    @Test func `removeFromWatchlist does nothing without an entry`() async {
        let watchlistMock = MockWatchlistService()
        let vm = makeVM(watchlistService: watchlistMock)
        await vm.removeFromWatchlist()
        #expect(watchlistMock.removeFromWatchlistCalls.isEmpty)
    }

    @Test func `removeFromWatchlist calls the service with the entry's id`() async {
        let watchlistMock = MockWatchlistService()
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem(id: 99, tmdbId: 1, mediaType: .movie)])
        let vm = makeVM(watchlistService: watchlistMock, store: store)
        await vm.checkWatchlistStatus()

        await vm.removeFromWatchlist()

        #expect(watchlistMock.removeFromWatchlistCalls.first == 99)
    }

    @Test func `removeFromWatchlist clears the entry on success`() async {
        let watchlistMock = MockWatchlistService()
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem(id: 1, tmdbId: 1, mediaType: .movie)])
        let vm = makeVM(watchlistService: watchlistMock, store: store)
        await vm.checkWatchlistStatus()

        await vm.removeFromWatchlist()

        #expect(vm.entry == nil)
        #expect(vm.isOnWatchlist == false)
    }

    // MARK: - toggleEpisodeWatched

    @Test func `toggleEpisodeWatched does nothing for movies`() async {
        let mediaMock = MockMediaDetailService()
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.toggleEpisodeWatched(season: 1, episode: 1)
        #expect(mediaMock.markEpisodeWatchedCalls.isEmpty)
        #expect(mediaMock.unmarkEpisodeWatchedCalls.isEmpty)
    }

    @Test func `toggleEpisodeWatched marks an unwatched episode`() async {
        let mediaMock = MockMediaDetailService()
        let vm = await tvVM(mediaMock, episodes: episodes(1))

        await vm.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(mediaMock.markEpisodeWatchedCalls.isEmpty == false)
        #expect(vm.episodes(inSeason: 1).first?.isWatched == true)
    }

    @Test func `toggleEpisodeWatched unmarks a watched episode`() async {
        let mediaMock = MockMediaDetailService()
        let vm = await tvVM(mediaMock, episodes: episodes(1), watched: [1])

        await vm.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(mediaMock.unmarkEpisodeWatchedCalls.isEmpty == false)
        #expect(vm.episodes(inSeason: 1).first?.isWatched == false)
    }

    @Test func `toggleEpisodeWatched adopts a status change from the backend`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.markEpisodeWatchedResult = .success(.completed)
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([
            TestFixtures.watchItem(id: 7, tmdbId: 5, mediaType: .tv, status: .completed)
        ])
        let vm = await tvVM(mediaMock, episodes: episodes(1), watchlistService: watchlistMock)

        await vm.toggleEpisodeWatched(season: 1, episode: 1)

        #expect(vm.entry == WatchlistEntry(id: 7, status: .completed))
    }

    // MARK: - toggleSeasonWatched

    @Test func `toggleSeasonWatched does nothing for movies`() async {
        let mediaMock = MockMediaDetailService()
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.toggleSeasonWatched(1)
        #expect(mediaMock.markSeasonWatchedCalls.isEmpty)
        #expect(mediaMock.unmarkSeasonWatchedCalls.isEmpty)
    }

    @Test func `toggleSeasonWatched marks the whole season when it is not finished`() async {
        let mediaMock = MockMediaDetailService()
        let vm = await tvVM(mediaMock, episodes: episodes(2), watched: [2])

        await vm.toggleSeasonWatched(1)

        #expect(mediaMock.markSeasonWatchedCalls.isEmpty == false)
        #expect(vm.episodes(inSeason: 1).allSatisfy { $0.isWatched })
    }

    @Test func `toggleSeasonWatched unmarks the whole season when it is finished`() async {
        let mediaMock = MockMediaDetailService()
        let vm = await tvVM(mediaMock, episodes: episodes(2), watched: [1, 2])

        await vm.toggleSeasonWatched(1)

        #expect(mediaMock.unmarkSeasonWatchedCalls.isEmpty == false)
        #expect(vm.episodes(inSeason: 1).allSatisfy { !$0.isWatched })
    }

    // MARK: - loadSeasonIfNeeded

    @Test func `loadSeasonIfNeeded skips the network when the season is already loaded`() async {
        let mediaMock = MockMediaDetailService()
        let vm = await tvVM(mediaMock, episodes: episodes(1))
        let callsAfterFirstLoad = mediaMock.fetchSeasonDetailCalls.count

        await vm.loadSeasonIfNeeded(1)

        #expect(mediaMock.fetchSeasonDetailCalls.count == callsAfterFirstLoad)
    }

    @Test func `loadSeasonIfNeeded merges the watched state`() async {
        let mediaMock = MockMediaDetailService()
        let vm = await tvVM(mediaMock, episodes: episodes(2), watched: [1])

        let loaded = vm.episodes(inSeason: 1)
        #expect(loaded.first { $0.episodeNumber == 1 }?.isWatched == true)
        #expect(loaded.first { $0.episodeNumber == 2 }?.isWatched == false)
    }

    /// The failure is scoped to the season that failed — the screen and the other
    /// seasons are untouched, which the single screen-wide error could not express.
    @Test func `loadSeasonIfNeeded fails into that season alone`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        mediaMock.fetchSeasonDetailResult = .failure(MockError.generic("season not found"))
        let vm = makeVM(type: .tv, id: 5, mediaDetailService: mediaMock)
        await vm.fetchDetails()

        await vm.loadSeasonIfNeeded(1)

        guard case .failed = vm.seasonState(1) else {
            return #expect(Bool(false), "expected the season to be .failed")
        }
        #expect(vm.episodes(inSeason: 1).isEmpty)
        #expect(vm.seasonState(2) == nil, "an untouched season stays untouched")
        guard case .loaded = vm.state else { return #expect(Bool(false), "the screen stays loaded") }
    }

    // MARK: - rateMedia

    @Test func `rateMedia updates userRating on success`() async {
        let vm = makeVM()
        await vm.rateMedia(rating: 4)
        #expect(vm.userRating == 4)
        #expect(vm.actionError == nil)
    }

    @Test func `rateMedia rolls the rating back on failure`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.rateMediaError = MockError.generic("rate failed")
        let vm = makeVM(mediaDetailService: mediaMock)

        await vm.rateMedia(rating: 5)

        #expect(vm.actionError != nil)
        #expect(vm.userRating == nil)
    }

    @Test func `dismissActionError clears the alert`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.rateMediaError = MockError.generic("rate failed")
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.rateMedia(rating: 5)

        vm.dismissActionError()

        #expect(vm.actionError == nil)
    }
}
