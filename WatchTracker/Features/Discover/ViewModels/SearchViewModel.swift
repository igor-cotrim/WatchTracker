import Foundation

/// The search half of Discover: the query, its filters, the debounced autocomplete
/// and the recent-search list.
@Observable
@MainActor
final class SearchViewModel {
    /// Bound to the search field, so it is the one property the view writes.
    var query = ""
    var selectedType: MediaType?
    var selectedYear: Int?

    private(set) var results: [MediaDetail] = []
    private(set) var suggestions: [MediaDetail] = []
    private(set) var history: [String] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Exposed so tests can await the debounced work instead of sleeping.
    private(set) var searchTask: Task<Void, Never>?

    private let service: any DiscoverServiceProtocol
    private let historyStore: SearchHistoryManager
    private let analytics: any AnalyticsTracking
    private let clock: any Clock<Duration>

    init(
        service: any DiscoverServiceProtocol,
        historyStore: SearchHistoryManager,
        analytics: any AnalyticsTracking,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.service = service
        self.historyStore = historyStore
        self.analytics = analytics
        self.clock = clock
    }

    var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            results = try await service.search(query: trimmed, type: selectedType, year: selectedYear)
            historyStore.save(query: trimmed)
            loadHistory()

            var properties: [String: Any] = ["query": trimmed, "result_count": results.count]
            if let selectedType { properties["search_type"] = selectedType.rawValue }
            if let selectedYear { properties["year"] = selectedYear }
            analytics.capture(.searchPerformed, properties: properties)
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    /// Called on every keystroke. Clearing the field drops both lists so the recent
    /// searches come back instead of stale results.
    func queryChanged() {
        guard isSearching else {
            searchTask?.cancel()
            results = []
            suggestions = []
            return
        }
        fetchSuggestions()
    }

    func fetchSuggestions() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }
        searchTask = Task { [clock] in
            try? await clock.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            // Autocomplete failures stay silent: the field keeps working and the user
            // never asked for this request.
            guard let results = try? await service.search(query: trimmed, type: nil, year: nil),
                  !Task.isCancelled else { return }
            suggestions = Array(results.prefix(8))
        }
    }

    // MARK: - History

    func loadHistory() {
        history = historyStore.load()
    }

    func removeHistoryItem(_ query: String) {
        historyStore.remove(query: query)
        loadHistory()
    }

    func clearHistory() {
        historyStore.clearAll()
        loadHistory()
    }

    func selectHistoryItem(_ query: String) {
        self.query = query
        Task { await search() }
    }
}
