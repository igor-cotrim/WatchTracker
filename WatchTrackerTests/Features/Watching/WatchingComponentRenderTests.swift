import SwiftUI
import Testing
@testable import WatchTracker

/// Renders `Features/Watching/Components/`, all previously at 0%.
///
/// `UpcomingRow` renders `localDaysUntilAir`, which is computed against `Date()` inside
/// the model. Rather than threading a clock through `UpcomingItem`, the fixtures are
/// expressed *relative to today* — so the "today" / "tomorrow" / "in N days" branches
/// are each reached no matter when the suite runs.
@MainActor
@Suite("Watching components render", .tags(.view, .pure))
struct WatchingComponentRenderTests {

    @Test func `watching row renders`() {
        let item = TestFixtures.continueWatchingItem()
        _ = render(WatchingRow(item: item, onMarkWatched: {}), height: 120)
    }

    @Test func `watching row skeleton renders`() {
        rasterize(WatchingRowSkeleton(), height: 120)
    }

    @Test(arguments: [0, 1, 5])
    func `upcoming row renders each air-date branch`(daysFromNow: Int) {
        let item = TestFixtures.upcomingItem(nextEpisodeDaysFromToday: daysFromNow)
        _ = render(UpcomingRow(item: item), height: 120)
    }

    @Test func `upcoming row renders with streaming providers`() {
        let item = TestFixtures.upcomingItem(
            nextEpisodeDaysFromToday: 3,
            watchProviders: ["Netflix", "Disney"]
        )
        _ = render(UpcomingRow(item: item), height: 120)
    }

    @Test(arguments: ["today", "this_week", "later"])
    func `upcoming section header renders each section`(key: String) {
        _ = render(UpcomingSectionHeader(sectionKey: key), height: 60)
    }
}
