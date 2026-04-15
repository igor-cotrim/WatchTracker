import Testing
@testable import WatchTracker

@Suite(.tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct BrowseGridViewModelTests {

    private func makeVM(pages: [[MediaDetail]]) -> BrowseGridViewModel {
        var pageIndex = 0
        return BrowseGridViewModel { _ in
            defer { pageIndex += 1 }
            guard pageIndex < pages.count else { return [] }
            return pages[pageIndex]
        }
    }

    private func makeErrorVM() -> BrowseGridViewModel {
        BrowseGridViewModel { _ in throw MockError.generic("network error") }
    }

    // MARK: - loadInitial

    @Test func `loadInitial calls fetchPage with page 1`() async {
        var receivedPage: Int?
        let vm = BrowseGridViewModel { page in
            receivedPage = page
            return []
        }
        await vm.loadInitial()
        #expect(receivedPage == 1)
    }

    @Test func `loadInitial sets results on success`() async {
        let items = [TestFixtures.mediaDetail(), TestFixtures.mediaDetail(id: 2)]
        let vm = makeVM(pages: [items])
        await vm.loadInitial()
        #expect(vm.results.count == 2)
    }

    @Test func `loadInitial sets hasMorePages true for non-empty response`() async {
        let vm = makeVM(pages: [[TestFixtures.mediaDetail()]])
        await vm.loadInitial()
        #expect(vm.hasMorePages == true)
    }

    @Test func `loadInitial sets hasMorePages false for empty response`() async {
        let vm = makeVM(pages: [[]])
        await vm.loadInitial()
        #expect(vm.hasMorePages == false)
    }

    @Test func `loadInitial sets errorMessage on failure`() async {
        let vm = makeErrorVM()
        await vm.loadInitial()
        #expect(vm.errorMessage != nil)
        #expect(vm.results.isEmpty)
    }

    @Test func `isLoading is false after loadInitial`() async {
        let vm = makeVM(pages: [[]])
        await vm.loadInitial()
        #expect(vm.isLoading == false)
    }

    // MARK: - loadMore

    @Test func `loadMore appends results and increments page`() async {
        let vm = makeVM(pages: [
            [TestFixtures.mediaDetail(id: 1)],    // page 1
            [TestFixtures.mediaDetail(id: 2)],    // page 2
        ])
        await vm.loadInitial()
        await vm.loadMore()
        #expect(vm.results.count == 2)
        #expect(vm.currentPage == 2)
    }

    @Test func `loadMore sets hasMorePages false on empty response`() async {
        let vm = makeVM(pages: [
            [TestFixtures.mediaDetail()],   // page 1
            [],                              // page 2 is empty
        ])
        await vm.loadInitial()
        await vm.loadMore()
        #expect(vm.hasMorePages == false)
    }

    @Test func `loadMore rolls back page on error`() async {
        var callCount = 0
        let vm = BrowseGridViewModel { _ in
            callCount += 1
            if callCount == 1 { return [TestFixtures.mediaDetail()] }
            throw MockError.generic("page 2 error")
        }
        await vm.loadInitial()
        let pageBeforeError = vm.currentPage
        await vm.loadMore()
        #expect(vm.currentPage == pageBeforeError, "Page should roll back after error")
        #expect(vm.errorMessage != nil)
    }

    @Test func `loadMore does nothing when hasMorePages is false`() async {
        var callCount = 0
        let vm = BrowseGridViewModel { _ in
            callCount += 1
            return []   // empty → hasMorePages = false
        }
        await vm.loadInitial()
        await vm.loadMore()
        #expect(callCount == 1, "loadMore should not call fetchPage when no more pages")
    }

    @Test func `three sequential loadMore calls accumulate results`() async {
        let vm = makeVM(pages: [
            [TestFixtures.mediaDetail(id: 1)],
            [TestFixtures.mediaDetail(id: 2)],
            [TestFixtures.mediaDetail(id: 3)],
            [],
        ])
        await vm.loadInitial()
        await vm.loadMore()
        await vm.loadMore()
        #expect(vm.results.count == 3)
        #expect(vm.currentPage == 3)
    }
}
