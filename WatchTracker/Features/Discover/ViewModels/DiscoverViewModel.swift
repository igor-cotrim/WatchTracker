import Foundation

enum DiscoverTab {
    case movies
    case tv
}

@Observable
@MainActor
final class DiscoverViewModel {
    // Tab selection
    var selectedTab: DiscoverTab = .movies

    // Movies content
    var trending: [MediaDetail] = []
    var nowPlaying: [MediaDetail] = []
    var popular: [MediaDetail] = []
    var topRated: [MediaDetail] = []
    var upcoming: [MediaDetail] = []

    // TV content
    var popularTV: [MediaDetail] = []
    var topRatedTV: [MediaDetail] = []
    var anime: [MediaDetail] = []

    // Shared
    var genres: [Genre] = []
    var providers: [StreamingProvider] = []

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
    private let service: any DiscoverServiceProtocol
    private let searchHistoryManager: SearchHistoryManager

    init(
        service: any DiscoverServiceProtocol = DiscoverService(),
        searchHistoryManager: SearchHistoryManager = SearchHistoryManager()
    ) {
        self.service = service
        self.searchHistoryManager = searchHistoryManager
    }

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Movies Fetching

    func fetchTrending() async {
        await fetch(\.trending) { try await self.service.fetchTrending() }
    }

    func fetchNowPlaying() async {
        await fetch(\.nowPlaying) { try await self.service.fetchNowPlaying() }
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

    // MARK: - TV Fetching

    func fetchPopularTV() async {
        await fetch(\.popularTV) { try await self.service.fetchPopular(type: .tv, page: nil) }
    }

    func fetchTopRatedTV() async {
        await fetch(\.topRatedTV) { try await self.service.fetchTopRated(type: .tv, page: nil) }
    }

    func fetchAnime() async {
        await fetch(\.anime) { try await self.service.discoverFiltered(type: .tv, genres: "16", originCountry: "JP", providers: nil, watchRegion: nil, sortBy: nil, page: nil) }
    }

    // MARK: - Shared Fetching

    func fetchGenres() async {
        await fetch(\.genres) { try await self.service.fetchGenres(type: .movie) }
    }

    func fetchProviders() async {
        await fetch(\.providers) { try await self.service.fetchProviders(type: .movie) }
    }

    // MARK: - Private Helper

    private func fetch<T>(_ keyPath: ReferenceWritableKeyPath<DiscoverViewModel, T>,
                          _ operation: () async throws -> T) async {
        do {
            self[keyPath: keyPath] = try await operation()
        } catch {
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
                    searchSuggestions = Array(results.prefix(5))
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
