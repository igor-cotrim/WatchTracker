import Foundation
import Testing
@testable import WatchTracker

@Suite("AnalyticsEvent", .tags(.pure, .service))
struct AnalyticsEventTests {

    @Test func `raw values are the snake_case names the dashboard expects`() {
        #expect(AnalyticsEvent.screenView.rawValue == "screen_view")
        #expect(AnalyticsEvent.detailViewed.rawValue == "detail_viewed")
        #expect(AnalyticsEvent.searchPerformed.rawValue == "search_performed")
        #expect(AnalyticsEvent.discoverProviderFilter.rawValue == "discover_provider_filter")
        #expect(AnalyticsEvent.watchlistAdded.rawValue == "watchlist_added")
        #expect(AnalyticsEvent.watchlistStatusChanged.rawValue == "watchlist_status_changed")
        #expect(AnalyticsEvent.watchlistRemoved.rawValue == "watchlist_removed")
        #expect(AnalyticsEvent.mediaRated.rawValue == "media_rated")
        #expect(AnalyticsEvent.ratingRemoved.rawValue == "rating_removed")
        #expect(AnalyticsEvent.providerLinkTapped.rawValue == "provider_link_tapped")
    }
}
