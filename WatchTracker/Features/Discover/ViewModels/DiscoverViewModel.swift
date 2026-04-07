import Foundation

@Observable
final class DiscoverViewModel {
    var trending: [MediaDetail] = []
    var searchResults: [MediaDetail] = []
    var nowPlaying: [MediaDetail] = []
    var topRated: [MediaDetail] = []
    var upcoming: [MediaDetail] = []
    var popular: [MediaDetail] = []
    var anime: [MediaDetail] = []
    var genres: [Genre] = []
    var providers: [StreamingProvider] = []
    var searchQuery = ""
    var isLoading = false
    var errorMessage: String?

    // Search filters
    var selectedSearchType: String?
    var selectedSearchYear: Int?

    // Search history
    var searchHistory: [String] = []

    // Autocomplete
    var searchSuggestions: [MediaDetail] = []
    private var searchTask: Task<Void, Never>?

    private let service = DiscoverService()
    private let searchHistoryManager = SearchHistoryManager()

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Topic Fetching

    func fetchTrending() async {
        do {
            trending = try await service.fetchTrending()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchNowPlaying() async {
        do {
            nowPlaying = try await service.fetchNowPlaying()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchTopRated() async {
        do {
            topRated = try await service.fetchTopRated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchUpcoming() async {
        do {
            upcoming = try await service.fetchUpcoming()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchPopular() async {
        do {
            popular = try await service.fetchPopular()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAnime() async {
        do {
            anime = try await service.discoverFiltered(type: "tv", genres: "16", originCountry: "JP")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchGenres() async {
        do {
            genres = try await service.fetchGenres()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchProviders() async {
        do {
            providers = try await service.fetchProviders()
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
                let results = try await service.search(query: query)
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
