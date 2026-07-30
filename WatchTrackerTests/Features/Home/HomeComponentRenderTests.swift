import SwiftUI
import Testing
@testable import WatchTracker

/// Renders `Features/Home/Components/`, all previously at 0%.
@MainActor
@Suite("Home components render", .tags(.view, .pure))
struct HomeComponentRenderTests {

    private func makeVM(items: [WatchItem] = []) -> WatchlistViewModel {
        let store = WatchlistStore()
        store.cachedItems = items
        return WatchlistViewModel(
            service: MockWatchlistService(),
            store: store,
            notifications: MockNotificationScheduler()
        )
    }

    @Test(arguments: MediaFilter.allCases)
    func `media filter tab bar renders each selection`(filter: MediaFilter) {
        _ = render(MediaFilterTabBar(selected: .constant(filter)), height: 60)
    }

    @Test func `status filter bar renders with an empty watchlist`() {
        _ = render(StatusFilterBar(viewModel: makeVM()), height: 80)
    }

    /// Counts per status only appear once the store has items, so this exercises the
    /// branch the empty case skips.
    @Test func `status filter bar renders counts for a populated watchlist`() {
        let items = [
            TestFixtures.watchItem(id: 1, status: .watching, posterPath: nil),
            TestFixtures.watchItem(id: 2, status: .watching, posterPath: nil),
            TestFixtures.watchItem(id: 3, status: .completed, posterPath: nil),
            TestFixtures.watchItem(id: 4, status: .planToWatch, posterPath: nil)
        ]
        _ = render(StatusFilterBar(viewModel: makeVM(items: items)), height: 80)
    }

    @Test func `watchlist card renders without a badge`() {
        let item = TestFixtures.watchItem(posterPath: nil)
        _ = render(WatchlistCardView(item: item), width: 180, height: 260)
    }

    /// The badge is the animated branch. Under the Unit plan it settles immediately via
    /// `MotionPolicy`; elsewhere it animates in. Either way this only checks that the
    /// branch renders, so the outcome does not depend on how the suite was launched.
    @Test func `watchlist card renders the new-episodes badge`() {
        let item = TestFixtures.watchItem(posterPath: nil, newEpisodesCount: 3)
        rasterize(WatchlistCardView(item: item), width: 180, height: 260)
    }

    @Test func `watchlist card renders without a title`() {
        _ = render(WatchlistCardView(item: TestFixtures.watchItem(posterPath: nil)), width: 180, height: 260)
    }
}
