import Foundation

@Observable
final class DiscoverViewModel {
    var trending: [MediaDetail] = []
    var searchResults: [MediaDetail] = []
    var nowPlaying: [MediaDetail] = []
    var searchQuery = ""
    var isLoading = false
    var errorMessage: String?

    private let service = DiscoverService()

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

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

    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isLoading = true
        do {
            searchResults = try await service.search(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
