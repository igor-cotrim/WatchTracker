import Testing
@testable import WatchTracker

@MainActor
@Suite(.tags(.viewModel))
struct WatchlistViewModelTests {

    private func makeVM() -> WatchlistViewModel {
        WatchlistViewModel(service: MockWatchlistService(), store: WatchlistStore())
    }

    // MARK: - items(for:) — pure filtering

    @Test func `items for all returns all items`() {
        let vm = makeVM()
        vm.allItems = [
            TestFixtures.watchItem(mediaType: .movie),
            TestFixtures.watchItem(id: 2, mediaType: .tv),
        ]
        #expect(vm.items(for: .all).count == 2)
    }

    @Test func `items for movie returns only movies`() {
        let vm = makeVM()
        vm.allItems = [
            TestFixtures.watchItem(id: 1, mediaType: .movie),
            TestFixtures.watchItem(id: 2, mediaType: .tv),
        ]
        let result = vm.items(for: .movie)
        #expect(result.count == 1)
        #expect(result.first?.mediaType == .movie)
    }

    @Test func `items for tv excludes anime`() {
        let vm = makeVM()
        vm.allItems = [
            TestFixtures.watchItem(id: 1, mediaType: .tv, isAnime: false),
            TestFixtures.watchItem(id: 2, mediaType: .tv, isAnime: true),
            TestFixtures.watchItem(id: 3, mediaType: .tv, isAnime: nil),
        ]
        let result = vm.items(for: .tv)
        // isAnime == true → excluded; isAnime == nil → included (not true); isAnime == false → included
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.isAnime != true })
    }

    @Test func `items for anime returns only anime tv shows`() {
        let vm = makeVM()
        vm.allItems = [
            TestFixtures.watchItem(id: 1, mediaType: .tv, isAnime: true),
            TestFixtures.watchItem(id: 2, mediaType: .tv, isAnime: false),
            TestFixtures.watchItem(id: 3, mediaType: .movie),
        ]
        let result = vm.items(for: .anime)
        #expect(result.count == 1)
        #expect(result.first?.isAnime == true)
    }

    @Test func `selectedStatus filters before media type filter`() {
        let vm = makeVM()
        vm.allItems = [
            TestFixtures.watchItem(id: 1, mediaType: .movie, status: .watching),
            TestFixtures.watchItem(id: 2, mediaType: .movie, status: .completed),
            TestFixtures.watchItem(id: 3, mediaType: .tv, status: .watching),
        ]
        vm.selectedStatus = .watching
        let result = vm.items(for: .movie)
        #expect(result.count == 1)
        #expect(result.first?.id == 1)
    }

    @Test func `items for all with empty allItems returns empty`() {
        let vm = makeVM()
        vm.allItems = []
        #expect(vm.items(for: .all).isEmpty)
    }

    // MARK: - count(for:)

    @Test(arguments: WatchlistStatus.allCases)
    func `count for status returns correct number`(status: WatchlistStatus) {
        let vm = makeVM()
        vm.allItems = [
            TestFixtures.watchItem(id: 1, status: .watching),
            TestFixtures.watchItem(id: 2, status: .watching),
            TestFixtures.watchItem(id: 3, status: .completed),
        ]
        switch status {
        case .watching:    #expect(vm.count(for: status) == 2)
        case .completed:   #expect(vm.count(for: status) == 1)
        case .planToWatch: #expect(vm.count(for: status) == 0)
        }
    }

    @Test func `count returns zero for empty list`() {
        let vm = makeVM()
        #expect(vm.count(for: .watching) == 0)
    }

    // MARK: - syncFromCache

    @Test func `syncFromCache updates allItems from non-empty store`() {
        let store = WatchlistStore()
        store.cachedItems = [TestFixtures.watchItem()]
        let vm = WatchlistViewModel(store: store)
        store.cachedItems = [TestFixtures.watchItem(), TestFixtures.watchItem(id: 2)]
        vm.syncFromCache()
        #expect(vm.allItems.count == 2)
    }

    @Test func `syncFromCache does not clear allItems when store is empty`() {
        let store = WatchlistStore()
        let vm = WatchlistViewModel(store: store)
        vm.allItems = [TestFixtures.watchItem()]
        store.cachedItems = []
        vm.syncFromCache()
        // Guard: empty cached items → allItems unchanged
        #expect(vm.allItems.count == 1)
    }

    // MARK: - fetchWatchlist

    @Suite(.tags(.viewModel, .async), .timeLimit(.minutes(1)))
    struct FetchTests {

        @Test func `fetchWatchlist populates allItems on success`() async {
            let mock = MockWatchlistService()
            mock.fetchWatchlistResult = .success([TestFixtures.watchItem()])
            let store = WatchlistStore()
            let vm = WatchlistViewModel(service: mock, store: store)
            await vm.fetchWatchlist()
            #expect(vm.allItems.count == 1)
            #expect(vm.errorMessage == nil)
        }

        @Test func `fetchWatchlist updates store cache on success`() async {
            let mock = MockWatchlistService()
            let item = TestFixtures.watchItem()
            mock.fetchWatchlistResult = .success([item])
            let store = WatchlistStore()
            let vm = WatchlistViewModel(service: mock, store: store)
            await vm.fetchWatchlist()
            #expect(store.cachedItems.count == 1)
            #expect(store.needsRefresh == false)
        }

        @Test func `fetchWatchlist sets errorMessage on failure`() async {
            let mock = MockWatchlistService()
            mock.fetchWatchlistResult = .failure(MockError.generic("network error"))
            let store = WatchlistStore()
            let vm = WatchlistViewModel(service: mock, store: store)
            await vm.fetchWatchlist()
            #expect(vm.errorMessage != nil)
            #expect(vm.allItems.isEmpty)
        }

        @Test func `fetchWatchlist skips network when cache is valid`() async {
            let mock = MockWatchlistService()
            mock.fetchWatchlistResult = .success([TestFixtures.watchItem()])
            let store = WatchlistStore()
            store.cachedItems = [TestFixtures.watchItem()]
            store.needsRefresh = false
            let vm = WatchlistViewModel(service: mock, store: store)
            await vm.fetchWatchlist(forceRefresh: false)
            #expect(mock.fetchWatchlistCallCount == 0)
        }

        @Test func `fetchWatchlist calls network when forceRefresh is true`() async {
            let mock = MockWatchlistService()
            mock.fetchWatchlistResult = .success([])
            let store = WatchlistStore()
            store.cachedItems = [TestFixtures.watchItem()]
            store.needsRefresh = false
            let vm = WatchlistViewModel(service: mock, store: store)
            await vm.fetchWatchlist(forceRefresh: true)
            #expect(mock.fetchWatchlistCallCount == 1)
        }

        @Test func `isLoading is false after successful fetch`() async {
            let mock = MockWatchlistService()
            mock.fetchWatchlistResult = .success([])
            let store = WatchlistStore()
            let vm = WatchlistViewModel(service: mock, store: store)
            await vm.fetchWatchlist()
            #expect(vm.isLoading == false)
        }

        @Test func `isLoading is false after failed fetch`() async {
            let mock = MockWatchlistService()
            mock.fetchWatchlistResult = .failure(MockError.generic("fail"))
            let store = WatchlistStore()
            let vm = WatchlistViewModel(service: mock, store: store)
            await vm.fetchWatchlist()
            #expect(vm.isLoading == false)
        }
    }
}
