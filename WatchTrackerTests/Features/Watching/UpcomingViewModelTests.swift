import Testing
@testable import WatchTracker

@Suite(.tags(.viewModel))
struct UpcomingViewModelTests {

    // MARK: - groupedItems section keys

    @Test(arguments: [
        (-5, "today"),
        (-1, "today"),
        (0, "today"),
        (1, "tomorrow"),
        (7, "later"),
        (100, "later"),
    ])
    func `groupedItems places item in correct section`(offset: Int, expectedSection: String) {
        let vm = UpcomingViewModel(service: MockWatchlistService())
        vm.items = [TestFixtures.upcomingItem(nextEpisodeDaysFromToday: offset)]
        let sections = vm.groupedItems
        let sectionKey = try! #require(sections.first?.sectionKey)
        #expect(sectionKey == expectedSection)
    }

    @Test func `groupedItems day 2 through 6 map to weekday names`() {
        let vm = UpcomingViewModel(service: MockWatchlistService())
        for offset in 2...6 {
            vm.items = [TestFixtures.upcomingItem(nextEpisodeDaysFromToday: offset)]
            let sections = vm.groupedItems
            let key = sections.first?.sectionKey ?? ""
            // Should not be "today", "tomorrow", or "later"
            #expect(key != "today")
            #expect(key != "tomorrow")
            #expect(key != "later")
            #expect(key.isEmpty == false)
        }
    }

    @Test func `groupedItems groups multiple items in same section`() {
        let vm = UpcomingViewModel(service: MockWatchlistService())
        vm.items = [
            TestFixtures.upcomingItem(tmdbId: 1, nextEpisodeDaysFromToday: 0),
            TestFixtures.upcomingItem(tmdbId: 2, nextEpisodeDaysFromToday: 0),
        ]
        let sections = vm.groupedItems
        let todaySection = sections.first { $0.sectionKey == "today" }
        #expect(todaySection?.items.count == 2)
    }

    @Test func `groupedItems orders sections today before tomorrow before later`() {
        let vm = UpcomingViewModel(service: MockWatchlistService())
        vm.items = [
            TestFixtures.upcomingItem(tmdbId: 1, nextEpisodeDaysFromToday: 7),   // later
            TestFixtures.upcomingItem(tmdbId: 2, nextEpisodeDaysFromToday: 0),   // today
            TestFixtures.upcomingItem(tmdbId: 3, nextEpisodeDaysFromToday: 1),   // tomorrow
        ]
        let sections = vm.groupedItems
        let keys = sections.map { $0.sectionKey }
        let todayIndex = keys.firstIndex(of: "today") ?? -1
        let tomorrowIndex = keys.firstIndex(of: "tomorrow") ?? -1
        let laterIndex = keys.firstIndex(of: "later") ?? -1
        #expect(todayIndex < tomorrowIndex)
        #expect(tomorrowIndex < laterIndex)
    }

    @Test func `groupedItems omits empty sections`() {
        let vm = UpcomingViewModel(service: MockWatchlistService())
        vm.items = [TestFixtures.upcomingItem(nextEpisodeDaysFromToday: 0)]
        let sections = vm.groupedItems
        #expect(sections.allSatisfy { !$0.items.isEmpty })
    }

    @Test func `groupedItems is empty when items is empty`() {
        let vm = UpcomingViewModel(service: MockWatchlistService())
        vm.items = []
        #expect(vm.groupedItems.isEmpty)
    }

    // MARK: - fetch (async)

    @Suite(.tags(.viewModel, .async), .timeLimit(.minutes(1)))
    struct FetchTests {

        @Test func `fetch populates items on success`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .success([
                TestFixtures.upcomingItem(nextEpisodeDaysFromToday: 1)
            ])
            let vm = UpcomingViewModel(service: mock)
            await vm.fetch()
            #expect(vm.items.count == 1)
            #expect(vm.errorMessage == nil)
        }

        @Test func `fetch sets errorMessage on failure`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .failure(MockError.generic("error"))
            let vm = UpcomingViewModel(service: mock)
            await vm.fetch()
            #expect(vm.errorMessage != nil)
            #expect(vm.items.isEmpty)
        }

        @Test func `isLoading is false after fetch`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .success([])
            let vm = UpcomingViewModel(service: mock)
            await vm.fetch()
            #expect(vm.isLoading == false)
        }
    }
}
