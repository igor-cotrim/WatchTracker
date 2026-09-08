import Foundation

/// Where one asynchronous list of titles is in its lifecycle.
///
/// Discover shows eleven lists that load independently, so each one carries its own
/// state instead of sharing a screen-wide `isLoading` / `errorMessage` pair that no
/// single row could ever describe correctly.
enum FeedState {
    case loading
    case loaded([MediaDetail])
    case failed(String)

    var items: [MediaDetail] {
        if case .loaded(let items) = self { items } else { [] }
    }

    var errorMessage: String? {
        if case .failed(let message) = self { message } else { nil }
    }

    var isLoading: Bool {
        if case .loading = self { true } else { false }
    }
}
