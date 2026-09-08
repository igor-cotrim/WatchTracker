import Foundation

/// The paginated grid behind every "see all" link, and the mood screens.
@Observable
@MainActor
final class BrowseGridViewModel {
    private(set) var state: FeedState = .loading

    /// Kept apart from `state`: appending a page leaves the grid on screen, so the footer
    /// spinner and the full-screen spinner are not the same situation — and a failed append
    /// must not blank out the results the user is already looking at.
    private(set) var isLoadingMore = false
    private(set) var currentPage = 1
    private(set) var hasMorePages = true

    private let feed: BrowseFeed
    private let service: any DiscoverServiceProtocol

    init(feed: BrowseFeed, service: any DiscoverServiceProtocol) {
        self.feed = feed
        self.service = service
    }

    var items: [MediaDetail] { state.items }

    func loadInitial() async {
        state = .loading
        currentPage = 1
        do {
            let items = try await feed.page(1, using: service)
            state = .loaded(items)
            hasMorePages = !items.isEmpty
        } catch {
            state = .failed(error.userFacingMessage)
        }
    }

    func loadMore() async {
        guard case .loaded(let existing) = state, hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let items = try await feed.page(nextPage, using: service)
            if items.isEmpty {
                hasMorePages = false
            } else {
                currentPage = nextPage
                state = .loaded(existing + items)
            }
        } catch {
            // The page the user is on is still valid, so the grid stays put and `currentPage`
            // is left where it was — scrolling to the end again retries the same page rather
            // than skipping it, which is what the old rollback (`currentPage -= 1`) did.
        }
    }
}
