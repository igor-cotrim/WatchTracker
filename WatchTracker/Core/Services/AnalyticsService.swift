import Foundation
import PostHog

final class AnalyticsService {
    static let shared = AnalyticsService()

    private var isStarted = false

    private init() {}

    func start() {
        guard !isStarted else { return }
        guard Config.posthogAPIKey.hasPrefix("phc_") else { return }

        let config = PostHogConfig(projectToken: Config.posthogAPIKey, host: Config.posthogHost)
        config.personProfiles = .identifiedOnly
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false
        config.sessionReplay = false

        PostHogSDK.shared.setup(config)
        isStarted = true
    }

    func capture(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        guard isStarted else { return }
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }
}

enum AnalyticsEvent: String {
    case screenView = "screen_view"
    case detailViewed = "detail_viewed"
    case searchPerformed = "search_performed"
    case discoverProviderFilter = "discover_provider_filter"
    case watchlistAdded = "watchlist_added"
    case watchlistStatusChanged = "watchlist_status_changed"
    case watchlistRemoved = "watchlist_removed"
    case mediaRated = "media_rated"
    case ratingRemoved = "rating_removed"
    case providerLinkTapped = "provider_link_tapped"
}
