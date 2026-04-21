import Testing
@testable import WatchTracker

@MainActor
@Suite(.tags(.viewModel), .timeLimit(.minutes(1)))
struct MediaDetailViewModelTests {

    private func makeVM(
        mediaDetailService: MockMediaDetailService? = nil,
        watchlistService: MockWatchlistService? = nil,
        store: WatchlistStore? = nil
    ) -> MediaDetailViewModel {
        MediaDetailViewModel(
            mediaDetailService: mediaDetailService ?? MockMediaDetailService(),
            watchlistService: watchlistService ?? MockWatchlistService(),
            store: store ?? WatchlistStore()
        )
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

    // MARK: - isSeasonAllWatched (pure)

    @Test func `isSeasonAllWatched returns false when season not loaded`() {
        let vm = makeVM()
        #expect(vm.isSeasonAllWatched(1) == false)
    }

    @Test func `isSeasonAllWatched returns false for empty episodes array`() {
        let vm = makeVM()
        vm.seasonEpisodes[1] = []
        #expect(vm.isSeasonAllWatched(1) == false)
    }

    @Test func `isSeasonAllWatched returns true when all watched`() {
        let vm = makeVM()
        vm.seasonEpisodes[1] = [
            TestFixtures.episode(episodeNumber: 1, isWatched: true),
            TestFixtures.episode(id: 2, episodeNumber: 2, isWatched: true),
        ]
        #expect(vm.isSeasonAllWatched(1) == true)
    }

    @Test func `isSeasonAllWatched returns false when any unwatched`() {
        let vm = makeVM()
        vm.seasonEpisodes[1] = [
            TestFixtures.episode(episodeNumber: 1, isWatched: true),
            TestFixtures.episode(id: 2, episodeNumber: 2, isWatched: false),
        ]
        #expect(vm.isSeasonAllWatched(1) == false)
    }

    @Test(arguments: [0, 1, 2, 3])
    func `isSeasonAllWatched for varying watch counts out of 3`(watchedCount: Int) {
        let vm = makeVM()
        vm.seasonEpisodes[1] = (1...3).map { n in
            TestFixtures.episode(id: n, episodeNumber: n, isWatched: n <= watchedCount)
        }
        #expect(vm.isSeasonAllWatched(1) == (watchedCount == 3))
    }

    // MARK: - displayStatus (pure)

    @Test func `displayStatus is Na Lista when watchlistStatus is nil`() {
        let vm = makeVM()
        #expect(vm.displayStatus == "Na Lista")
    }

    @Test(arguments: WatchlistStatus.allCases)
    func `displayStatus matches watchlistStatus displayName`(status: WatchlistStatus) {
        let vm = makeVM()
        vm.watchlistStatus = status
        #expect(vm.displayStatus == status.displayName)
    }

    // MARK: - checkWatchlistStatus (reads from injected store)

    @Test func `checkWatchlistStatus sets not on watchlist when store is empty`() async {
        let store = WatchlistStore()
        let vm = makeVM(store: store)
        await vm.checkWatchlistStatus()
        #expect(vm.isOnWatchlist == false)
        #expect(vm.watchlistItemId == nil)
        #expect(vm.watchlistStatus == nil)
    }

    @Test func `checkWatchlistStatus finds matching item in store`() async {
        let store = WatchlistStore()
        // Default mediaId=0, mediaType=.movie so use matching item
        store.cachedItems = [TestFixtures.watchItem(id: 5, tmdbId: 0, mediaType: .movie, status: .watching)]
        let vm = makeVM(store: store)
        await vm.checkWatchlistStatus()
        #expect(vm.isOnWatchlist == true)
        #expect(vm.watchlistItemId == 5)
        #expect(vm.watchlistStatus == .watching)
    }

    @Test func `checkWatchlistStatus ignores item with wrong mediaType`() async {
        let store = WatchlistStore()
        // mediaType = .tv doesn't match default .movie
        store.cachedItems = [TestFixtures.watchItem(tmdbId: 0, mediaType: .tv)]
        let vm = makeVM(store: store)
        await vm.checkWatchlistStatus()
        #expect(vm.isOnWatchlist == false)
    }

    @Test func `checkWatchlistStatus resets isCheckingStatus via defer`() async {
        let vm = makeVM()
        await vm.checkWatchlistStatus()
        #expect(vm.isCheckingStatus == false)
    }

    // MARK: - fetchDetails

    @Test func `fetchDetails populates media on success`() async {
        let mock = MockMediaDetailService()
        mock.fetchMediaDetailResult = .success(TestFixtures.mediaDetail(id: 42))
        let vm = makeVM(mediaDetailService: mock)
        await vm.fetchDetails(type: .movie, id: 42)
        #expect(vm.media?.id == 42)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func `fetchDetails sets errorMessage on failure`() async {
        let mock = MockMediaDetailService()
        mock.fetchMediaDetailResult = .failure(MockError.generic("not found"))
        let vm = makeVM(mediaDetailService: mock)
        await vm.fetchDetails(type: .movie, id: 1)
        #expect(vm.errorMessage != nil)
        #expect(vm.media == nil)
    }

    @Test func `fetchDetails detects watchlistStatus change after initial load`() async {
        let mock = MockMediaDetailService()
        let store = WatchlistStore()

        // First call to set initial state
        mock.fetchMediaDetailResult = .success(TestFixtures.mediaDetail(watchlistStatus: .watching))
        let vm = makeVM(mediaDetailService: mock, store: store)
        await vm.fetchDetails(type: .movie, id: 1)
        await vm.checkWatchlistStatus()  // sets hasLoadedInitialStatus = true

        // Second call where backend returns a different status
        mock.fetchMediaDetailResult = .success(TestFixtures.mediaDetail(watchlistStatus: .completed))
        await vm.fetchDetails(type: .movie, id: 1)

        #expect(vm.watchlistStatus == .completed)
        #expect(store.needsRefresh == true)
    }

    // MARK: - addToWatchlist

    @Test func `addToWatchlist does not mark all episodes for movie`() async {
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([])
        let vm = makeVM(watchlistService: watchlistMock)
        await vm.addToWatchlist(status: .completed)
        // mediaType defaults to .movie → markAllEpisodesWatched should NOT be called
        #expect(watchlistMock.markAllEpisodesWatchedCalls.isEmpty)
    }

    @Test func `addToWatchlist calls markAllEpisodesWatched for completed TV`() async throws {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 10))
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([])
        let vm = makeVM(mediaDetailService: mediaMock, watchlistService: watchlistMock)
        await vm.fetchDetails(type: .tv, id: 10)
        await vm.addToWatchlist(status: .completed)
        #expect(watchlistMock.markAllEpisodesWatchedCalls.isEmpty == false)
    }

    @Test func `addToWatchlist does not call markAllEpisodesWatched for non-completed TV`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 10))
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([])
        let vm = makeVM(mediaDetailService: mediaMock, watchlistService: watchlistMock)
        await vm.fetchDetails(type: .tv, id: 10)
        await vm.addToWatchlist(status: .watching)
        #expect(watchlistMock.markAllEpisodesWatchedCalls.isEmpty)
    }

    @Test func `addToWatchlist routes to updateStatus when item already on watchlist`() async {
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([
            TestFixtures.watchItem(id: 42, tmdbId: 0, mediaType: .movie, status: .completed)
        ])
        let store = WatchlistStore()
        store.cachedItems = [
            TestFixtures.watchItem(id: 42, tmdbId: 0, mediaType: .movie, status: .watching)
        ]
        let vm = makeVM(watchlistService: watchlistMock, store: store)
        await vm.checkWatchlistStatus()  // populates watchlistItemId = 42
        await vm.addToWatchlist(status: .completed)
        #expect(watchlistMock.updateStatusCalls.first?.id == 42)
        #expect(watchlistMock.updateStatusCalls.first?.status == .completed)
        #expect(watchlistMock.addToWatchlistCalls.isEmpty)
    }

    @Test func `syncLocalStateFromCache picks latest id when duplicates exist`() async {
        // Simulates legacy data created before the DB unique constraint:
        // multiple rows with same (tmdbId, mediaType). VM should reflect the latest.
        let store = WatchlistStore()
        store.cachedItems = [
            TestFixtures.watchItem(id: 10, tmdbId: 0, mediaType: .movie, status: .watching),
            TestFixtures.watchItem(id: 25, tmdbId: 0, mediaType: .movie, status: .completed),
            TestFixtures.watchItem(id: 17, tmdbId: 0, mediaType: .movie, status: .planToWatch),
        ]
        let vm = makeVM(store: store)
        await vm.checkWatchlistStatus()
        #expect(vm.watchlistItemId == 25)
        #expect(vm.watchlistStatus == .completed)
    }

    // MARK: - removeFromWatchlist

    @Test func `removeFromWatchlist does nothing when watchlistItemId is nil`() async {
        let watchlistMock = MockWatchlistService()
        let vm = makeVM(watchlistService: watchlistMock)
        await vm.removeFromWatchlist()
        #expect(watchlistMock.removeFromWatchlistCalls.isEmpty)
    }

    @Test func `removeFromWatchlist calls service with correct id`() async {
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([])
        let store = WatchlistStore()
        store.cachedItems = [TestFixtures.watchItem(id: 99, tmdbId: 0, mediaType: .movie)]
        let vm = makeVM(watchlistService: watchlistMock, store: store)
        await vm.checkWatchlistStatus()  // sets watchlistItemId = 99
        await vm.removeFromWatchlist()
        #expect(watchlistMock.removeFromWatchlistCalls.first == 99)
    }

    @Test func `removeFromWatchlist clears local state on success`() async {
        let watchlistMock = MockWatchlistService()
        watchlistMock.fetchWatchlistResult = .success([])
        let store = WatchlistStore()
        store.cachedItems = [TestFixtures.watchItem(id: 1, tmdbId: 0, mediaType: .movie)]
        let vm = makeVM(watchlistService: watchlistMock, store: store)
        await vm.checkWatchlistStatus()
        await vm.removeFromWatchlist()
        #expect(vm.isOnWatchlist == false)
        #expect(vm.watchlistItemId == nil)
        #expect(vm.watchlistStatus == nil)
    }

    // MARK: - toggleEpisodeWatched

    @Test func `toggleEpisodeWatched does nothing for movies`() async {
        let mediaMock = MockMediaDetailService()
        let vm = makeVM(mediaDetailService: mediaMock)
        // default mediaType = .movie
        await vm.toggleEpisodeWatched(season: 1, episode: 1)
        #expect(mediaMock.markEpisodeWatchedCalls.isEmpty)
        #expect(mediaMock.unmarkEpisodeWatchedCalls.isEmpty)
    }

    @Test func `toggleEpisodeWatched marks unwatched episode as watched`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        mediaMock.markEpisodeWatchedResult = .success(nil)
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.fetchDetails(type: .tv, id: 5)
        vm.seasonEpisodes[1] = [TestFixtures.episode(episodeNumber: 1, isWatched: false)]
        await vm.toggleEpisodeWatched(season: 1, episode: 1)
        #expect(mediaMock.markEpisodeWatchedCalls.isEmpty == false)
        #expect(vm.seasonEpisodes[1]?.first?.isWatched == true)
    }

    @Test func `toggleEpisodeWatched unmarks watched episode`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        mediaMock.unmarkEpisodeWatchedResult = .success(nil)
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.fetchDetails(type: .tv, id: 5)
        vm.seasonEpisodes[1] = [TestFixtures.episode(episodeNumber: 1, isWatched: true)]
        await vm.toggleEpisodeWatched(season: 1, episode: 1)
        #expect(mediaMock.unmarkEpisodeWatchedCalls.isEmpty == false)
        #expect(vm.seasonEpisodes[1]?.first?.isWatched == false)
    }

    @Test func `toggleEpisodeWatched updates watchlistStatus on statusChanged`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        mediaMock.markEpisodeWatchedResult = .success(.completed)
        let watchlistMock = MockWatchlistService()

        watchlistMock.fetchWatchlistResult = .success([
            TestFixtures.watchItem(id: 7, tmdbId: 5, mediaType: .tv, status: .completed)
        ])
        let store = WatchlistStore()
        let vm = makeVM(mediaDetailService: mediaMock, watchlistService: watchlistMock, store: store)
        await vm.fetchDetails(type: .tv, id: 5)
        vm.seasonEpisodes[1] = [TestFixtures.episode(episodeNumber: 1, isWatched: false)]
        await vm.toggleEpisodeWatched(season: 1, episode: 1)
        #expect(vm.watchlistStatus == .completed)
        #expect(vm.isOnWatchlist == true)
        #expect(vm.watchlistItemId == 7)
    }

    // MARK: - toggleSeasonWatched

    @Test func `toggleSeasonWatched does nothing for movies`() async {
        let mediaMock = MockMediaDetailService()
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.toggleSeasonWatched(1)
        #expect(mediaMock.markSeasonWatchedCalls.isEmpty)
        #expect(mediaMock.unmarkSeasonWatchedCalls.isEmpty)
    }

    @Test func `toggleSeasonWatched marks all episodes watched when not all watched`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        mediaMock.markSeasonWatchedResult = .success(nil)
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.fetchDetails(type: .tv, id: 5)
        vm.seasonEpisodes[1] = [
            TestFixtures.episode(episodeNumber: 1, isWatched: false),
            TestFixtures.episode(id: 2, episodeNumber: 2, isWatched: true),
        ]
        await vm.toggleSeasonWatched(1)
        #expect(mediaMock.markSeasonWatchedCalls.isEmpty == false)
        #expect(vm.seasonEpisodes[1]?.allSatisfy(\.isWatched) == true)
    }

    @Test func `toggleSeasonWatched unmarks all when all watched`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        mediaMock.unmarkSeasonWatchedResult = .success(nil)
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.fetchDetails(type: .tv, id: 5)
        vm.seasonEpisodes[1] = [
            TestFixtures.episode(episodeNumber: 1, isWatched: true),
            TestFixtures.episode(id: 2, episodeNumber: 2, isWatched: true),
        ]
        await vm.toggleSeasonWatched(1)
        #expect(mediaMock.unmarkSeasonWatchedCalls.isEmpty == false)
        #expect(vm.seasonEpisodes[1]?.allSatisfy { !$0.isWatched } == true)
    }

    // MARK: - loadSeasonIfNeeded

    @Test func `loadSeasonIfNeeded skips network when season already loaded`() async {
        let mediaMock = MockMediaDetailService()
        let vm = makeVM(mediaDetailService: mediaMock)
        vm.seasonEpisodes[1] = [TestFixtures.episode()]
        await vm.loadSeasonIfNeeded(1)
        #expect(mediaMock.fetchSeasonDetailCalls.isEmpty)
    }

    @Test func `loadSeasonIfNeeded loads and merges watched state`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        let episodes = [
            TestFixtures.episode(id: 1, episodeNumber: 1),
            TestFixtures.episode(id: 2, episodeNumber: 2),
        ]
        mediaMock.fetchSeasonDetailResult = .success(TestFixtures.season(seasonNumber: 1, episodes: episodes))
        mediaMock.fetchWatchedEpisodesResult = .success([1])  // episode 1 is watched
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.fetchDetails(type: .tv, id: 5)
        await vm.loadSeasonIfNeeded(1)
        let loaded = try! #require(vm.seasonEpisodes[1])
        #expect(loaded.first(where: { $0.episodeNumber == 1 })?.isWatched == true)
        #expect(loaded.first(where: { $0.episodeNumber == 2 })?.isWatched == false)
    }

    @Test func `loadSeasonIfNeeded sets errorMessage on failure`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.fetchMediaDetailResult = .success(TestFixtures.tvDetail(id: 5))
        mediaMock.fetchSeasonDetailResult = .failure(MockError.generic("season not found"))
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.fetchDetails(type: .tv, id: 5)
        await vm.loadSeasonIfNeeded(1)
        #expect(vm.errorMessage != nil)
        #expect(vm.seasonEpisodes[1] == nil)
        #expect(vm.isLoadingSeason.contains(1) == false, "isLoadingSeason should be cleaned up on error")
    }

    // MARK: - rateMedia

    @Test func `rateMedia updates userRating on success`() async {
        let mediaMock = MockMediaDetailService()
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.rateMedia(rating: 4)
        #expect(vm.userRating == 4)
        #expect(vm.errorMessage == nil)
    }

    @Test func `rateMedia sets errorMessage on failure`() async {
        let mediaMock = MockMediaDetailService()
        mediaMock.rateMediaError = MockError.generic("rate failed")
        let vm = makeVM(mediaDetailService: mediaMock)
        await vm.rateMedia(rating: 5)
        #expect(vm.errorMessage != nil)
        #expect(vm.userRating == nil)
    }
}
