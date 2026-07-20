import Foundation

@Observable
@MainActor
final class DiscoverViewModel {
    // Generic content (no provider filter)
    var trending: [MediaDetail] = []
    var nowPlaying: [MediaDetail] = []
    var popular: [MediaDetail] = []
    var topRated: [MediaDetail] = []
    var upcoming: [MediaDetail] = []

    // Shared
    var providers: [StreamingProvider] = []

    // Provider-scoped content (movie + tv merged)
    var selectedProvider: StreamingProvider?
    var newOnProvider: [MediaDetail] = []
    var topTenOnProvider: [MediaDetail] = []
    var trendingOnProvider: [MediaDetail] = []
    var acclaimedOnProvider: [MediaDetail] = []

    // Search
    var searchResults: [MediaDetail] = []
    var searchQuery = ""
    var isLoading = false
    var errorMessage: String?
    var selectedSearchType: MediaType?
    var selectedSearchYear: Int?
    var searchHistory: [String] = []
    var searchSuggestions: [MediaDetail] = []

    private var searchTask: Task<Void, Never>?
    private var providerTask: Task<Void, Never>?
    private let service: DiscoverServiceProtocol
    private let searchHistoryManager: SearchHistoryManager
    private let lastProviderKey = "discover.lastProviderId"

    init(
        service: DiscoverServiceProtocol,
        searchHistoryManager: SearchHistoryManager
    ) {
        self.service = service
        self.searchHistoryManager = searchHistoryManager
    }

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Generic Fetching

    func fetchTrending() async {
        await fetch(\.trending) { try await self.service.fetchTrending(page: nil) }
    }

    func fetchNowPlaying() async {
        await fetch(\.nowPlaying) { try await self.service.fetchNowPlaying(page: nil) }
    }

    func fetchPopular() async {
        await fetch(\.popular) { try await self.service.fetchPopular(type: .movie, page: nil) }
    }

    func fetchTopRated() async {
        await fetch(\.topRated) { try await self.service.fetchTopRated(type: .movie, page: nil) }
    }

    func fetchUpcoming() async {
        await fetch(\.upcoming) { try await self.service.fetchUpcoming(page: nil) }
    }

    func fetchProviders() async {
        await fetch(\.providers) { try await self.service.fetchProviders(type: .movie) }
    }

    // MARK: - Provider-Scoped Fetching

    func restoreLastProviderIfNeeded() {
        guard selectedProvider == nil else { return }
        let storedId = UserDefaults.standard.object(forKey: lastProviderKey) as? Int
        guard let storedId, let provider = providers.first(where: { $0.providerId == storedId }) else { return }
        selectProvider(provider)
    }

    func selectProvider(_ provider: StreamingProvider?) {
        guard provider?.providerId != selectedProvider?.providerId else { return }

        providerTask?.cancel()
        selectedProvider = provider

        guard let provider else {
            UserDefaults.standard.removeObject(forKey: lastProviderKey)
            clearProviderContent()
            return
        }

        UserDefaults.standard.set(provider.providerId, forKey: lastProviderKey)
        AnalyticsService.shared.capture(.discoverProviderFilter, properties: [
            "provider_id": provider.providerId,
            "provider_name": provider.providerName
        ])
        providerTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.loadProviderContent(for: provider)
        }
    }

    private func loadProviderContent(for provider: StreamingProvider) async {
        async let new: () = fetchNewOnProvider(provider)
        async let top: () = fetchTopTenOnProvider(provider)
        async let trending: () = fetchTrendingOnProvider(provider)
        async let acclaimed: () = fetchAcclaimedOnProvider(provider)
        _ = await (new, top, trending, acclaimed)
    }

    private func clearProviderContent() {
        newOnProvider = []
        topTenOnProvider = []
        trendingOnProvider = []
        acclaimedOnProvider = []
    }

    private func fetchNewOnProvider(_ provider: StreamingProvider) async {
        let dateString = thirtyDaysAgoString()
        await fetch(\.newOnProvider) {
            async let moviesTask = self.service.discoverFiltered(
                type: .movie, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "primary_release_date.desc", page: nil,
                releaseDateGte: dateString, firstAirDateGte: nil
            )
            async let tvTask = self.service.discoverFiltered(
                type: .tv, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "first_air_date.desc", page: nil,
                releaseDateGte: nil, firstAirDateGte: dateString
            )
            let movies = try await moviesTask
            let tv = try await tvTask
            return Self.mergedByReleaseDateDesc(movies, tv)
        }
    }

    private func fetchTopTenOnProvider(_ provider: StreamingProvider) async {
        await fetch(\.topTenOnProvider) {
            async let moviesTask = self.service.discoverFiltered(
                type: .movie, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "popularity.desc", page: nil,
                releaseDateGte: nil, firstAirDateGte: nil
            )
            async let tvTask = self.service.discoverFiltered(
                type: .tv, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "popularity.desc", page: nil,
                releaseDateGte: nil, firstAirDateGte: nil
            )
            let movies = try await moviesTask
            let tv = try await tvTask
            return Array(Self.interleaved(movies, tv).prefix(10))
        }
    }

    private func fetchTrendingOnProvider(_ provider: StreamingProvider) async {
        await fetch(\.trendingOnProvider) {
            async let moviesTask = self.service.discoverFiltered(
                type: .movie, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "popularity.desc", page: 2,
                releaseDateGte: nil, firstAirDateGte: nil
            )
            async let tvTask = self.service.discoverFiltered(
                type: .tv, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "popularity.desc", page: 2,
                releaseDateGte: nil, firstAirDateGte: nil
            )
            let movies = try await moviesTask
            let tv = try await tvTask
            return Self.interleaved(movies, tv)
        }
    }

    private func fetchAcclaimedOnProvider(_ provider: StreamingProvider) async {
        await fetch(\.acclaimedOnProvider) {
            async let moviesTask = self.service.discoverFiltered(
                type: .movie, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "vote_average.desc", page: nil,
                releaseDateGte: nil, firstAirDateGte: nil
            )
            async let tvTask = self.service.discoverFiltered(
                type: .tv, genres: nil, originCountry: nil,
                providers: String(provider.providerId), watchRegion: "BR",
                sortBy: "vote_average.desc", page: nil,
                releaseDateGte: nil, firstAirDateGte: nil
            )
            let movies = try await moviesTask
            let tv = try await tvTask
            return Self.interleaved(movies, tv)
        }
    }

    // MARK: - Merge helpers

    private static func interleaved(_ a: [MediaDetail], _ b: [MediaDetail]) -> [MediaDetail] {
        var result: [MediaDetail] = []
        let maxCount = max(a.count, b.count)
        result.reserveCapacity(a.count + b.count)
        for i in 0..<maxCount {
            if i < a.count { result.append(a[i]) }
            if i < b.count { result.append(b[i]) }
        }
        return result
    }

    private static func mergedByReleaseDateDesc(_ a: [MediaDetail], _ b: [MediaDetail]) -> [MediaDetail] {
        (a + b).sorted { lhs, rhs in
            let lhsDate = lhs.releaseDate ?? lhs.firstAirDate ?? ""
            let rhsDate = rhs.releaseDate ?? rhs.firstAirDate ?? ""
            return lhsDate > rhsDate
        }
    }

    private func thirtyDaysAgoString() -> String {
        let date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    // MARK: - Private Helper

    private func fetch<T>(_ keyPath: ReferenceWritableKeyPath<DiscoverViewModel, T>,
                          _ operation: () async throws -> T) async {
        do {
            let value = try await operation()
            guard !Task.isCancelled else { return }
            self[keyPath: keyPath] = value
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search

    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isLoading = true
        do {
            searchResults = try await service.search(
                query: query,
                type: selectedSearchType,
                year: selectedSearchYear
            )
            searchHistoryManager.save(query: query)
            loadSearchHistory()
            var eventProps: [String: Any] = [
                "query": query,
                "result_count": searchResults.count
            ]
            if let type = selectedSearchType { eventProps["search_type"] = type.rawValue }
            if let year = selectedSearchYear { eventProps["year"] = year }
            AnalyticsService.shared.capture(.searchPerformed, properties: eventProps)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchSuggestions() {
        searchTask?.cancel()
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchSuggestions = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let results = try await service.search(query: query, type: nil, year: nil)
                if !Task.isCancelled {
                    searchSuggestions = Array(results.prefix(8))
                }
            } catch {
                // Silently ignore autocomplete errors
            }
        }
    }

    // MARK: - Search History

    func loadSearchHistory() {
        searchHistory = searchHistoryManager.load()
    }

    func removeSearchHistoryItem(_ query: String) {
        searchHistoryManager.remove(query: query)
        loadSearchHistory()
    }

    func clearSearchHistory() {
        searchHistoryManager.clearAll()
        loadSearchHistory()
    }

    func selectHistoryItem(_ query: String) {
        searchQuery = query
        Task { await search() }
    }
}
