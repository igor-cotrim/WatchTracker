import Testing
import Foundation
@testable import WatchTracker

@MainActor
@Suite(.tags(.viewModel), .timeLimit(.minutes(1)))
struct DiscoverViewModelTests {

    // MARK: - isSearching

    @Test func `isSearching is false for empty string`() {
        let vm = DiscoverViewModel()
        vm.searchQuery = ""
        #expect(vm.isSearching == false)
    }

    @Test func `isSearching is false for whitespace only`() {
        let vm = DiscoverViewModel()
        vm.searchQuery = "   "
        #expect(vm.isSearching == false)
    }

    @Test func `isSearching is true for non-empty query`() {
        let vm = DiscoverViewModel()
        vm.searchQuery = "batman"
        #expect(vm.isSearching == true)
    }

    @Test func `isSearching is true for padded query`() {
        let vm = DiscoverViewModel()
        vm.searchQuery = "  batman  "
        #expect(vm.isSearching == true)
    }

    // MARK: - search()

    @Test func `search with empty trimmed query clears results without calling service`() async {
        let mock = MockDiscoverService()
        let vm = DiscoverViewModel(service: mock)
        vm.searchResults = [TestFixtures.mediaDetail()]
        vm.searchQuery = "   "
        await vm.search()
        #expect(vm.searchResults.isEmpty)
        #expect(mock.searchCallCount == 0)
    }

    @Test func `search calls service with trimmed query`() async {
        let mock = MockDiscoverService()
        mock.searchResult = .success([])
        let vm = DiscoverViewModel(service: mock)
        vm.searchQuery = "  batman  "
        await vm.search()
        #expect(mock.lastSearchQuery == "batman")
    }

    @Test func `search populates searchResults on success`() async {
        let mock = MockDiscoverService()
        mock.searchResult = .success([TestFixtures.mediaDetail()])
        let vm = DiscoverViewModel(service: mock)
        vm.searchQuery = "batman"
        await vm.search()
        #expect(vm.searchResults.count == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test func `search saves query to history`() async {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let mock = MockDiscoverService()
        mock.searchResult = .success([])
        let historyManager = SearchHistoryManager(userDefaults: defaults)
        let vm = DiscoverViewModel(service: mock, searchHistoryManager: historyManager)
        vm.searchQuery = "batman"
        await vm.search()
        #expect(vm.searchHistory.contains("batman"))
    }

    @Test func `search sets errorMessage on failure`() async {
        let mock = MockDiscoverService()
        mock.searchResult = .failure(MockError.generic("network fail"))
        let vm = DiscoverViewModel(service: mock)
        vm.searchQuery = "batman"
        await vm.search()
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }

    @Test func `isLoading is false after search completes`() async {
        let mock = MockDiscoverService()
        mock.searchResult = .success([])
        let vm = DiscoverViewModel(service: mock)
        vm.searchQuery = "batman"
        await vm.search()
        #expect(vm.isLoading == false)
    }

    // MARK: - fetchSuggestions

    @Test func `fetchSuggestions with empty query clears suggestions without service call`() async {
        let mock = MockDiscoverService()
        let vm = DiscoverViewModel(service: mock)
        vm.searchSuggestions = [TestFixtures.mediaDetail()]
        vm.searchQuery = ""
        vm.fetchSuggestions()
        #expect(vm.searchSuggestions.isEmpty)
        #expect(mock.searchCallCount == 0)
    }

    @Test func `fetchSuggestions after debounce calls service and caps at 5`() async throws {
        let mock = MockDiscoverService()
        mock.searchResult = .success(Array(repeating: TestFixtures.mediaDetail(), count: 10))
        let vm = DiscoverViewModel(service: mock)
        vm.searchQuery = "batman"
        vm.fetchSuggestions()
        try await Task.sleep(for: .milliseconds(600))
        await Task.yield()
        #expect(mock.searchCallCount == 1)
        #expect(vm.searchSuggestions.count == 5)
    }

    @Test func `fetchSuggestions cancels previous task on new query`() async throws {
        let mock = MockDiscoverService()
        mock.searchResult = .success([TestFixtures.mediaDetail()])

        // Track which queries reach the service
        let vm = DiscoverViewModel(service: mock)
        vm.searchQuery = "first"
        vm.fetchSuggestions()
        vm.searchQuery = "second"
        vm.fetchSuggestions()
        try await Task.sleep(for: .milliseconds(600))
        await Task.yield()
        #expect(mock.searchCallCount == 1, "Only second query should fire after cancellation")
        #expect(mock.lastSearchQuery == "second")
    }

    // MARK: - fetchAnime

    @Test func `fetchAnime calls discoverFiltered with genre 16 and JP origin`() async {
        let mock = MockDiscoverService()
        mock.discoverFilteredResult = .success([])
        let vm = DiscoverViewModel(service: mock)
        await vm.fetchAnime()
        let call = mock.discoverFilteredCalls.first
        #expect(call?.type == .tv)
        #expect(call?.genres == "16")
        #expect(call?.originCountry == "JP")
    }

    // MARK: - History management

    @Test func `clearSearchHistory empties searchHistory`() {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let historyManager = SearchHistoryManager(userDefaults: defaults)
        historyManager.save(query: "batman")
        let vm = DiscoverViewModel(searchHistoryManager: historyManager)
        vm.loadSearchHistory()
        vm.clearSearchHistory()
        #expect(vm.searchHistory.isEmpty)
    }

    @Test func `removeSearchHistoryItem removes specific item`() {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let historyManager = SearchHistoryManager(userDefaults: defaults)
        historyManager.save(query: "batman")
        historyManager.save(query: "superman")
        let vm = DiscoverViewModel(searchHistoryManager: historyManager)
        vm.loadSearchHistory()
        vm.removeSearchHistoryItem("superman")
        #expect(vm.searchHistory.contains("superman") == false)
        #expect(vm.searchHistory.contains("batman"))
    }

    // MARK: - Content fetching

    @Test func `fetchTrending populates trending on success`() async {
        let mock = MockDiscoverService()
        mock.fetchTrendingResult = .success([TestFixtures.mediaDetail(id: 1), TestFixtures.mediaDetail(id: 2)])
        let vm = DiscoverViewModel(service: mock)
        await vm.fetchTrending()
        #expect(vm.trending.count == 2)
        #expect(vm.errorMessage == nil)
    }

    @Test func `fetchTrending sets errorMessage on failure`() async {
        let mock = MockDiscoverService()
        mock.fetchTrendingResult = .failure(MockError.generic("error"))
        let vm = DiscoverViewModel(service: mock)
        await vm.fetchTrending()
        #expect(vm.errorMessage != nil)
    }
}
