import Foundation

@Observable
@MainActor
final class BrowseGridViewModel {
    var results: [MediaDetail] = []
    var isLoading = true
    var errorMessage: String?

    private(set) var currentPage = 1
    private(set) var hasMorePages = true
    private let fetchPage: (Int) async throws -> [MediaDetail]

    init(fetchPage: @escaping (Int) async throws -> [MediaDetail]) {
        self.fetchPage = fetchPage
    }

    func loadInitial() async {
        isLoading = true
        errorMessage = nil
        do {
            let items = try await fetchPage(1)
            results = items
            hasMorePages = !items.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        currentPage += 1
        do {
            let items = try await fetchPage(currentPage)
            if items.isEmpty {
                hasMorePages = false
            } else {
                results.append(contentsOf: items)
            }
        } catch {
            currentPage -= 1
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
