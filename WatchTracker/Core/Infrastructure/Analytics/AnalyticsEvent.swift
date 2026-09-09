import Foundation

enum AnalyticsEvent: String {
    case screenView = "screen_view"
    case detailViewed = "detail_viewed"
    case searchPerformed = "search_performed"
    case discoverProviderFilter = "discover_provider_filter"
    case discoverFilterApplied = "discover_filter_applied"
    case watchlistAdded = "watchlist_added"
    case watchlistStatusChanged = "watchlist_status_changed"
    case watchlistRemoved = "watchlist_removed"
    case mediaRated = "media_rated"
    case ratingRemoved = "rating_removed"
    case providerLinkTapped = "provider_link_tapped"
    case trailerOpened = "trailer_opened"
    case personViewed = "person_viewed"
    case dataExported = "data_exported"
}
