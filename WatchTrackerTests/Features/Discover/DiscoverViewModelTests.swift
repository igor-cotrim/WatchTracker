import Testing
import Foundation
@testable import WatchTracker

@MainActor
@Suite(.tags(.viewModel), .timeLimit(.minutes(1)))
struct DiscoverViewModelTests {

    /// Every ViewModel gets its own `UserDefaults` suite and a clock that never
    /// sleeps, so the debounce paths run instantly and suites can't see each other's
    /// persisted provider selection.
    private final class Harness {
        let service = MockDiscoverService()
        let analytics = MockAnalytics()
        let clock = ImmediateClock()
        let defaults: UserDefaults
        let history: SearchHistoryManager
        let viewModel: DiscoverViewModel
        private let suiteName: String

        init(now: @escaping @Sendable () -> Date = Date.init) {
            suiteName = "test-\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suiteName)!
            history = SearchHistoryManager(userDefaults: defaults)
            viewModel = DiscoverViewModel(
                service: service,
                searchHistoryManager: history,
                analytics: analytics,
                userDefaults: defaults,
                clock: clock,
                now: now
            )
        }

        deinit { defaults.removePersistentDomain(forName: suiteName) }
    }

    private func makeHarness(now: @escaping @Sendable () -> Date = Date.init) -> Harness {
        Harness(now: now)
    }

    // MARK: - isSearching

    @Test(arguments: [
        (query: "", expected: false),
        (query: "   ", expected: false),
        (query: "batman", expected: true),
        (query: "  batman  ", expected: true),
    ])
    func `isSearching ignores whitespace`(query: String, expected: Bool) {
        let harness = makeHarness()
        harness.viewModel.searchQuery = query
        #expect(harness.viewModel.isSearching == expected)
    }

    // MARK: - search()

    @Test func `search with empty trimmed query clears results without calling service`() async {
        let harness = makeHarness()
        harness.viewModel.searchResults = [TestFixtures.mediaDetail()]
        harness.viewModel.searchQuery = "   "

        await harness.viewModel.search()

        #expect(harness.viewModel.searchResults.isEmpty)
        #expect(harness.service.searchCallCount == 0)
    }

    @Test func `search calls service with trimmed query`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([])
        harness.viewModel.searchQuery = "  batman  "

        await harness.viewModel.search()

        #expect(harness.service.lastSearchQuery == "batman")
    }

    @Test func `search populates searchResults on success`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail()])
        harness.viewModel.searchQuery = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.searchResults.count == 1)
        #expect(harness.viewModel.errorMessage == nil)
    }

    @Test func `search saves query to history`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([])
        harness.viewModel.searchQuery = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.searchHistory.contains("batman"))
    }

    @Test func `search sets errorMessage on failure`() async {
        let harness = makeHarness()
        harness.service.searchResult = .failure(MockError.generic("network fail"))
        harness.viewModel.searchQuery = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.errorMessage != nil)
        #expect(harness.viewModel.isLoading == false)
    }

    @Test func `isLoading is false after search completes`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([])
        harness.viewModel.searchQuery = "batman"

        await harness.viewModel.search()

        #expect(harness.viewModel.isLoading == false)
    }

    @Test func `search captures an analytics event with the result count`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail(), TestFixtures.mediaDetail()])
        harness.viewModel.searchQuery = "batman"
        harness.viewModel.selectedSearchType = .movie
        harness.viewModel.selectedSearchYear = 2021

        await harness.viewModel.search()

        let properties = harness.analytics.properties(for: .searchPerformed)
        #expect(properties?["query"] as? String == "batman")
        #expect(properties?["result_count"] as? Int == 2)
        #expect(properties?["search_type"] as? String == "movie")
        #expect(properties?["year"] as? Int == 2021)
    }

    @Test func `search omits optional filters from the analytics event`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([])
        harness.viewModel.searchQuery = "batman"

        await harness.viewModel.search()

        let properties = harness.analytics.properties(for: .searchPerformed)
        #expect(properties?["search_type"] == nil)
        #expect(properties?["year"] == nil)
    }

    @Test func `a failed search does not capture an analytics event`() async {
        let harness = makeHarness()
        harness.service.searchResult = .failure(MockError.generic("boom"))
        harness.viewModel.searchQuery = "batman"

        await harness.viewModel.search()

        #expect(!harness.analytics.capturedEvents.contains(.searchPerformed))
    }

    // MARK: - fetchSuggestions

    @Test func `fetchSuggestions with empty query clears suggestions without service call`() async {
        let harness = makeHarness()
        harness.viewModel.searchSuggestions = [TestFixtures.mediaDetail()]
        harness.viewModel.searchQuery = ""

        harness.viewModel.fetchSuggestions()

        #expect(harness.viewModel.searchSuggestions.isEmpty)
        #expect(harness.service.searchCallCount == 0)
    }

    @Test func `fetchSuggestions after debounce calls service and caps at 8`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success(Array(repeating: TestFixtures.mediaDetail(), count: 10))
        harness.viewModel.searchQuery = "batman"

        harness.viewModel.fetchSuggestions()
        await harness.viewModel.searchTask?.value

        #expect(harness.service.searchCallCount == 1)
        #expect(harness.viewModel.searchSuggestions.count == 8)
    }

    @Test func `fetchSuggestions debounces by 300ms`() async {
        let harness = makeHarness()
        harness.viewModel.searchQuery = "batman"

        harness.viewModel.fetchSuggestions()
        await harness.viewModel.searchTask?.value

        #expect(harness.clock.sleeps == [.milliseconds(300)])
    }

    @Test func `fetchSuggestions cancels the previous task on a new query`() async {
        let harness = makeHarness()
        harness.service.searchResult = .success([TestFixtures.mediaDetail()])

        harness.viewModel.searchQuery = "first"
        harness.viewModel.fetchSuggestions()
        let firstTask = harness.viewModel.searchTask

        harness.viewModel.searchQuery = "second"
        harness.viewModel.fetchSuggestions()

        await firstTask?.value
        await harness.viewModel.searchTask?.value

        #expect(harness.service.searchCallCount == 1, "Only the second query should reach the service")
        #expect(harness.service.lastSearchQuery == "second")
    }

    @Test func `fetchSuggestions swallows service errors`() async {
        let harness = makeHarness()
        harness.viewModel.searchSuggestions = [TestFixtures.mediaDetail()]
        harness.service.searchResult = .failure(MockError.generic("boom"))
        harness.viewModel.searchQuery = "batman"

        harness.viewModel.fetchSuggestions()
        await harness.viewModel.searchTask?.value

        // Autocomplete failures are silent — no error banner over the search field.
        #expect(harness.viewModel.errorMessage == nil)
    }

    // MARK: - History management

    @Test func `clearSearchHistory empties searchHistory`() {
        let harness = makeHarness()
        harness.history.save(query: "batman")
        harness.viewModel.loadSearchHistory()

        harness.viewModel.clearSearchHistory()

        #expect(harness.viewModel.searchHistory.isEmpty)
    }

    @Test func `removeSearchHistoryItem removes specific item`() {
        let harness = makeHarness()
        harness.history.save(query: "batman")
        harness.history.save(query: "superman")
        harness.viewModel.loadSearchHistory()

        harness.viewModel.removeSearchHistoryItem("superman")

        #expect(harness.viewModel.searchHistory.contains("superman") == false)
        #expect(harness.viewModel.searchHistory.contains("batman"))
    }

    // MARK: - Provider selection

    @Test func `selectProvider persists the choice and captures analytics`() async {
        let harness = makeHarness()
        let netflix = TestFixtures.streamingProvider(providerId: 8, providerName: "Netflix")

        harness.viewModel.selectProvider(netflix)
        await harness.viewModel.providerTask?.value

        #expect(harness.viewModel.selectedProvider?.providerId == 8)
        #expect(harness.defaults.object(forKey: "discover.lastProviderId") as? Int == 8)

        let properties = harness.analytics.properties(for: .discoverProviderFilter)
        #expect(properties?["provider_id"] as? Int == 8)
        #expect(properties?["provider_name"] as? String == "Netflix")
    }

    @Test func `selecting the same provider twice is a no-op`() async {
        let harness = makeHarness()
        let netflix = TestFixtures.streamingProvider(providerId: 8)

        harness.viewModel.selectProvider(netflix)
        await harness.viewModel.providerTask?.value
        harness.viewModel.selectProvider(netflix)

        #expect(harness.analytics.capturedEvents.filter { $0 == .discoverProviderFilter }.count == 1)
    }

    @Test func `deselecting clears persisted state and provider content`() async {
        let harness = makeHarness()
        harness.viewModel.selectProvider(TestFixtures.streamingProvider(providerId: 8))
        await harness.viewModel.providerTask?.value
        harness.viewModel.newOnProvider = [TestFixtures.mediaDetail()]

        harness.viewModel.selectProvider(nil)

        #expect(harness.viewModel.selectedProvider == nil)
        #expect(harness.viewModel.newOnProvider.isEmpty)
        #expect(harness.defaults.object(forKey: "discover.lastProviderId") == nil)
    }

    @Test func `restoreLastProviderIfNeeded reselects the persisted provider`() async {
        let harness = makeHarness()
        harness.defaults.set(8, forKey: "discover.lastProviderId")
        harness.viewModel.providers = [TestFixtures.streamingProvider(providerId: 8)]

        harness.viewModel.restoreLastProviderIfNeeded()
        await harness.viewModel.providerTask?.value

        #expect(harness.viewModel.selectedProvider?.providerId == 8)
    }

    @Test func `restoreLastProviderIfNeeded ignores a provider that is no longer offered`() {
        let harness = makeHarness()
        harness.defaults.set(999, forKey: "discover.lastProviderId")
        harness.viewModel.providers = [TestFixtures.streamingProvider(providerId: 8)]

        harness.viewModel.restoreLastProviderIfNeeded()

        #expect(harness.viewModel.selectedProvider == nil)
    }

    @Test func `restoreLastProviderIfNeeded does nothing when a provider is already selected`() async {
        let harness = makeHarness()
        let netflix = TestFixtures.streamingProvider(providerId: 8)
        harness.viewModel.providers = [netflix, TestFixtures.streamingProvider(providerId: 337)]
        harness.viewModel.selectProvider(netflix)
        await harness.viewModel.providerTask?.value

        harness.defaults.set(337, forKey: "discover.lastProviderId")
        harness.viewModel.restoreLastProviderIfNeeded()

        #expect(harness.viewModel.selectedProvider?.providerId == 8)
    }

    // MARK: - Content fetching

    @Test func `fetchTrending populates trending on success`() async {
        let harness = makeHarness()
        harness.service.fetchTrendingResult = .success([TestFixtures.mediaDetail(id: 1), TestFixtures.mediaDetail(id: 2)])

        await harness.viewModel.fetchTrending()

        #expect(harness.viewModel.trending.count == 2)
        #expect(harness.viewModel.errorMessage == nil)
    }

    @Test func `fetchTrending sets errorMessage on failure`() async {
        let harness = makeHarness()
        harness.service.fetchTrendingResult = .failure(MockError.generic("error"))

        await harness.viewModel.fetchTrending()

        #expect(harness.viewModel.errorMessage != nil)
    }

    // MARK: - Date window

    @Test func `thirtyDaysAgoString formats the window start in UTC`() {
        let fixed = Date(timeIntervalSince1970: 1_768_478_400)  // 2026-01-15T12:00:00Z
        let harness = makeHarness(now: { fixed })
        #expect(harness.viewModel.thirtyDaysAgoString() == "2025-12-16")
    }
}

// MARK: - Merge helpers

@Suite("DiscoverViewModel merge helpers", .tags(.pure, .viewModel))
@MainActor
struct DiscoverMergeHelperTests {

    private func detail(id: Int, releaseDate: String? = nil) -> MediaDetail {
        TestFixtures.mediaDetail(id: id, releaseDate: releaseDate)
    }

    @Test func `interleaved alternates between the two lists`() {
        let merged = DiscoverViewModel.interleaved(
            [detail(id: 1), detail(id: 2)],
            [detail(id: 10), detail(id: 20)]
        )
        #expect(merged.map(\.id) == [1, 10, 2, 20])
    }

    @Test func `interleaved appends the remainder of the longer list`() {
        let merged = DiscoverViewModel.interleaved(
            [detail(id: 1), detail(id: 2), detail(id: 3)],
            [detail(id: 10)]
        )
        #expect(merged.map(\.id) == [1, 10, 2, 3])
    }

    @Test func `interleaved handles an empty first list`() {
        let merged = DiscoverViewModel.interleaved([], [detail(id: 10), detail(id: 20)])
        #expect(merged.map(\.id) == [10, 20])
    }

    @Test func `interleaved of two empty lists is empty`() {
        #expect(DiscoverViewModel.interleaved([], []).isEmpty)
    }

    @Test func `mergedByReleaseDateDesc sorts newest first`() {
        let merged = DiscoverViewModel.mergedByReleaseDateDesc(
            [detail(id: 1, releaseDate: "2020-01-01"), detail(id: 2, releaseDate: "2024-06-01")],
            [detail(id: 3, releaseDate: "2022-03-01")]
        )
        #expect(merged.map(\.id) == [2, 3, 1])
    }

    @Test func `mergedByReleaseDateDesc sorts items without a date last`() {
        let merged = DiscoverViewModel.mergedByReleaseDateDesc(
            [detail(id: 1, releaseDate: nil)],
            [detail(id: 2, releaseDate: "2020-01-01")]
        )
        #expect(merged.map(\.id) == [2, 1])
    }

    @Test func `mergedByReleaseDateDesc keeps every element`() {
        let merged = DiscoverViewModel.mergedByReleaseDateDesc(
            [detail(id: 1), detail(id: 2)],
            [detail(id: 3)]
        )
        #expect(merged.count == 3)
    }
}
