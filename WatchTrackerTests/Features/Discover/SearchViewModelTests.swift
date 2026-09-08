import Testing
import Foundation
@testable import WatchTracker

@MainActor
@Suite("SearchViewModel", .tags(.viewModel), .timeLimit(.minutes(1)))
struct SearchViewModelTests {

    /// Every view model gets its own `UserDefaults` suite and a clock that never sleeps,
    /// so the debounce paths run instantly and suites can't see each other's history.
    private final class Harness {
        let service = MockDiscoverService()
        let analytics = MockAnalytics()
        let clock = ImmediateClock()
        let defaults: UserDefaults
        let history: SearchHistoryManager
        let viewModel: SearchViewModel
        private let suiteName: String

        init() {
            suiteName = "test-\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suiteName)!
            history = SearchHistoryManager(userDefaults: defaults)
            viewModel = SearchViewModel(
                service: service,
                historyStore: history,
                analytics: analytics,
                clock: clock
            )
        }

        deinit { defaults.removePersistentDomain(forName: suiteName) }
    }

    private func makeHarness() -> Harness { Harness() }

    // MARK: - isSearching

    @Test(arguments: [
        (query: "", expected: false),
        (query: "   ", expected: false),
        (query: "batman", expected: true),
        (query: "  batman  ", expected: true),
    ])
    func `isSearching ignores whitespace`(query: String, expected: Bool) {
        let harness = makeHarness()
        harness.viewModel.query = query
        #expect(harness.viewModel.isSearching == expected)
    }

    // MARK: - search()

    @Test func `search with an empty trimmed query clears results without calling the service`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail()])
        harness.viewModel.query = "batman"
        await harness.viewModel.search()

        harness.viewModel.query = "   "
        await harness.viewModel.search()

        #expect(harness.viewModel.results.isEmpty)
        #expect(harness.service.searchCallCount == 1)
    }

    @Test func `search calls the service with a trimmed query`() async {
        let harness = makeHarness()
        harness.viewModel.query = "  batman  "

        await harness.viewModel.search()

        #expect(harness.service.lastSearchQuery == "batman")
    }

    @Test func `search publishes the results`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail()])
        harness.viewModel.query = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.results.count == 1)
        #expect(harness.viewModel.errorMessage == nil)
    }

    @Test func `search saves the query to history`() async {
        let harness = makeHarness()
        harness.viewModel.query = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.history.contains("batman"))
    }

    @Test func `search surfaces a failure and stops loading`() async {
        let harness = makeHarness()
        harness.service.searchResult = .failure(MockError.generic("network fail"))
        harness.viewModel.query = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.errorMessage != nil)
        #expect(harness.viewModel.isLoading == false)
    }

    @Test func `isLoading is false once search completes`() async {
        let harness = makeHarness()
        harness.viewModel.query = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.isLoading == false)
    }

    @Test func `search captures an analytics event with the result count`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail(), TestFixtures.mediaDetail()])
        harness.viewModel.query = "batman"
        harness.viewModel.selectedType = .movie
        harness.viewModel.selectedYear = 2021

        await harness.viewModel.search()

        let properties = harness.analytics.properties(for: .searchPerformed)
        #expect(properties?["query"] as? String == "batman")
        #expect(properties?["result_count"] as? Int == 2)
        #expect(properties?["search_type"] as? String == "movie")
        #expect(properties?["year"] as? Int == 2021)
    }

    @Test func `search omits optional filters from the analytics event`() async {
        let harness = makeHarness()
        harness.viewModel.query = "batman"

        await harness.viewModel.search()

        let properties = harness.analytics.properties(for: .searchPerformed)
        #expect(properties?["search_type"] == nil)
        #expect(properties?["year"] == nil)
    }

    @Test func `a failed search does not capture an analytics event`() async {
        let harness = makeHarness()
        harness.service.searchResult = .failure(MockError.generic("boom"))
        harness.viewModel.query = "batman"

        await harness.viewModel.search()

        #expect(!harness.analytics.capturedEvents.contains(.searchPerformed))
    }

    // MARK: - Suggestions

    @Test func `fetchSuggestions with an empty query calls nothing`() async {
        let harness = makeHarness()
        harness.viewModel.query = ""

        harness.viewModel.fetchSuggestions()

        #expect(harness.viewModel.suggestions.isEmpty)
        #expect(harness.service.searchCallCount == 0)
    }

    @Test func `fetchSuggestions caps the list at 8`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success(Array(repeating: TestFixtures.mediaDetail(), count: 10))
        harness.viewModel.query = "batman"

        harness.viewModel.fetchSuggestions()
        await harness.viewModel.searchTask?.value

        #expect(harness.service.searchCallCount == 1)
        #expect(harness.viewModel.suggestions.count == 8)
    }

    @Test func `fetchSuggestions debounces by 300ms`() async {
        let harness = makeHarness()
        harness.viewModel.query = "batman"

        harness.viewModel.fetchSuggestions()
        await harness.viewModel.searchTask?.value

        #expect(harness.clock.sleeps == [.milliseconds(300)])
    }

    @Test func `fetchSuggestions cancels the previous task on a new query`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail()])

        harness.viewModel.query = "first"
        harness.viewModel.fetchSuggestions()
        let firstTask = harness.viewModel.searchTask

        harness.viewModel.query = "second"
        harness.viewModel.fetchSuggestions()

        await firstTask?.value
        await harness.viewModel.searchTask?.value

        #expect(harness.service.searchCallCount == 1, "Only the second query should reach the service")
        #expect(harness.service.lastSearchQuery == "second")
    }

    @Test func `fetchSuggestions swallows service errors`() async {
        let harness = makeHarness()
        harness.service.searchResult = .failure(MockError.generic("boom"))
        harness.viewModel.query = "batman"

        harness.viewModel.fetchSuggestions()
        await harness.viewModel.searchTask?.value

        // Autocomplete failures are silent — no error banner over the search field.
        #expect(harness.viewModel.errorMessage == nil)
    }

    /// What the view calls on every keystroke: emptying the field must put the recent
    /// searches back rather than leaving the last results on screen.
    @Test func `clearing the query drops results and suggestions`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail()])
        harness.viewModel.query = "batman"
        await harness.viewModel.search()
        harness.viewModel.fetchSuggestions()
        await harness.viewModel.searchTask?.value

        harness.viewModel.query = ""
        harness.viewModel.queryChanged()

        #expect(harness.viewModel.results.isEmpty)
        #expect(harness.viewModel.suggestions.isEmpty)
    }

    // MARK: - History

    @Test func `clearHistory empties the list`() {
        let harness = makeHarness()
        harness.history.save(query: "batman")
        harness.viewModel.loadHistory()

        harness.viewModel.clearHistory()

        #expect(harness.viewModel.history.isEmpty)
    }

    @Test func `removeHistoryItem removes only that item`() {
        let harness = makeHarness()
        harness.history.save(query: "batman")
        harness.history.save(query: "superman")
        harness.viewModel.loadHistory()

        harness.viewModel.removeHistoryItem("superman")

        #expect(harness.viewModel.history.contains("superman") == false)
        #expect(harness.viewModel.history.contains("batman"))
    }
}
