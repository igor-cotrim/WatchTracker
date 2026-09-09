import Testing
@testable import WatchTracker

@MainActor
@Suite(.tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct BrowseGridViewModelTests {

    /// `.trending` is the simplest feed — one call, one page — so it is the one used to
    /// exercise pagination. What `BrowseFeed` builds is covered by `BrowseFeedTests`.
    private func makeVM(pages: [[MediaDetail]]) -> (BrowseGridViewModel, MockDiscoverService) {
        let service = MockDiscoverService()
        service.trendingPages = pages
        return (BrowseGridViewModel(feed: .trending, service: service), service)
    }

    private func makeErrorVM() -> BrowseGridViewModel {
        let service = MockDiscoverService()
        service.fetchTrendingResult = .failure(MockError.generic("network error"))
        return BrowseGridViewModel(feed: .trending, service: service)
    }

    // MARK: - loadInitial

    @Test func `loadInitial asks for page 1`() async {
        let (vm, service) = makeVM(pages: [[]])
        await vm.loadInitial()
        #expect(service.trendingPagesRequested == [1])
    }

    @Test func `loadInitial loads the first page`() async {
        let (vm, _) = makeVM(pages: [[TestFixtures.mediaDetail(), TestFixtures.mediaDetail(id: 2)]])
        await vm.loadInitial()
        #expect(vm.items.count == 2)
        guard case .loaded = vm.state else { return #expect(Bool(false), "expected .loaded") }
    }

    @Test func `loadInitial sets hasMorePages true for a non-empty page`() async {
        let (vm, _) = makeVM(pages: [[TestFixtures.mediaDetail()]])
        await vm.loadInitial()
        #expect(vm.hasMorePages)
    }

    @Test func `loadInitial sets hasMorePages false for an empty page`() async {
        let (vm, _) = makeVM(pages: [[]])
        await vm.loadInitial()
        #expect(vm.hasMorePages == false)
    }

    @Test func `loadInitial fails into the state, with nothing to show`() async {
        let vm = makeErrorVM()
        await vm.loadInitial()
        guard case .failed(let message) = vm.state else {
            return #expect(Bool(false), "expected .failed")
        }
        #expect(!message.isEmpty)
        #expect(vm.items.isEmpty)
    }

    @Test func `loadInitial leaves nothing loading behind it`() async {
        let (vm, _) = makeVM(pages: [[]])
        await vm.loadInitial()
        #expect(vm.state.isLoading == false)
        #expect(vm.isLoadingMore == false)
    }

    // MARK: - loadMore

    @Test func `loadMore appends the next page`() async {
        let (vm, _) = makeVM(pages: [
            [TestFixtures.mediaDetail(id: 1)],
            [TestFixtures.mediaDetail(id: 2)]
        ])
        await vm.loadInitial()
        await vm.loadMore()
        #expect(vm.items.count == 2)
        #expect(vm.currentPage == 2)
    }

    @Test func `loadMore stops paginating on an empty page`() async {
        let (vm, _) = makeVM(pages: [[TestFixtures.mediaDetail()], []])
        await vm.loadInitial()
        await vm.loadMore()
        #expect(vm.hasMorePages == false)
    }

    /// The distinction the old single `isLoading` / `errorMessage` pair could not draw:
    /// a page that fails to append must leave the grid exactly as the user sees it, and
    /// must not skip that page on the next attempt.
    @Test func `a failed append keeps the results already on screen`() async {
        let service = FailAfterFirstPage()
        let vm = BrowseGridViewModel(feed: .trending, service: service)

        await vm.loadInitial()
        let pageBeforeError = vm.currentPage
        await vm.loadMore()

        #expect(vm.currentPage == pageBeforeError)
        #expect(vm.items.count == 1)
        guard case .loaded = vm.state else { return #expect(Bool(false), "expected .loaded") }
    }

    @Test func `loadMore does nothing once there are no more pages`() async {
        let (vm, service) = makeVM(pages: [[]])
        await vm.loadInitial()
        await vm.loadMore()
        #expect(service.trendingPagesRequested == [1])
    }

    @Test func `three sequential loadMore calls accumulate`() async {
        let (vm, _) = makeVM(pages: [
            [TestFixtures.mediaDetail(id: 1)],
            [TestFixtures.mediaDetail(id: 2)],
            [TestFixtures.mediaDetail(id: 3)],
            []
        ])
        await vm.loadInitial()
        await vm.loadMore()
        await vm.loadMore()
        #expect(vm.items.count == 3)
        #expect(vm.currentPage == 3)
    }
}

/// Serves page 1 and then throws, which is the shape `MockDiscoverService`'s scripted
/// pages cannot express (they never fail).
@MainActor
private final class FailAfterFirstPage: DiscoverServiceProtocol {
    private var callCount = 0

    func fetchTrending(page: Int?) async throws -> [MediaDetail] {
        callCount += 1
        guard callCount == 1 else { throw MockError.generic("page 2 error") }
        return [TestFixtures.mediaDetail()]
    }

    func search(query: String, type: MediaType?, year: Int?) async throws -> [MediaDetail] { [] }
    func discover(provider: String?, type: MediaType?, region: String?) async throws -> [MediaDetail] { [] }
    func discoverFiltered(_ query: DiscoverQuery) async throws -> [MediaDetail] { [] }
    func fetchNowPlaying(page: Int?) async throws -> [MediaDetail] { [] }
    func fetchTopRated(type: MediaType, page: Int?) async throws -> [MediaDetail] { [] }
    func fetchUpcoming(page: Int?) async throws -> [MediaDetail] { [] }
    func fetchPopular(type: MediaType, page: Int?) async throws -> [MediaDetail] { [] }
    func fetchGenres(type: MediaType) async throws -> [Genre] { [] }
    func fetchProviders(type: MediaType) async throws -> [StreamingProvider] { [] }
}
