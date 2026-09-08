import Foundation

/// Where the detail screen is in loading the title itself.
///
/// Replaces the `media` / `isLoading` / `errorMessage` triple, which allowed states the
/// screen has no rendering for — a title *and* an error, or neither with nothing in flight.
enum MediaDetailState {
    case idle
    case loading
    case loaded(MediaDetail)
    case failed(String)

    var media: MediaDetail? {
        if case .loaded(let media) = self { media } else { nil }
    }
}

/// Where one season's episode list is. Seasons load on expand and independently of each
/// other, so each carries its own state instead of being spread across a `[Int: [Episode]]`
/// and a parallel `Set<Int>` of the ones still in flight.
enum SeasonState {
    case loading
    case loaded([Episode])
    case failed(String)

    var episodes: [Episode] {
        if case .loaded(let episodes) = self { episodes } else { [] }
    }

    var isLoading: Bool {
        if case .loading = self { true } else { false }
    }
}

/// The user's watchlist row for the title on screen.
///
/// One optional value in place of `isOnWatchlist` / `watchlistItemId` / `watchlistStatus`,
/// which were only ever written and cleared together — three properties that could disagree
/// but never legitimately did.
struct WatchlistEntry: Equatable {
    let id: Int
    let status: WatchlistStatus
}
