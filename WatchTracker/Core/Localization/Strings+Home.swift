import Foundation

extension Strings {
    // MARK: - Home

    enum Home {
        static var title: String { String(localized: "home.title") }
        static var continueWatching: String { String(localized: "home.continue_watching") }
    }

    // MARK: - Watchlist / Cards

    enum Watchlist {
        static var emptyTitle: String { String(localized: "watchlist.empty.title") }
        static var emptySubtitle: String { String(localized: "watchlist.empty.subtitle") }
        static var emptyWatchingTitle: String { String(localized: "watchlist.empty.watching.title") }
        static var emptyWatchingSubtitle: String { String(localized: "watchlist.empty.watching.subtitle") }
        static var emptyPlanTitle: String { String(localized: "watchlist.empty.plan_to_watch.title") }
        static var emptyPlanSubtitle: String { String(localized: "watchlist.empty.plan_to_watch.subtitle") }
        static var emptyCompletedTitle: String { String(localized: "watchlist.empty.completed.title") }
        static var emptyCompletedSubtitle: String { String(localized: "watchlist.empty.completed.subtitle") }
        static var discoverButton: String { String(localized: "watchlist.empty.discover_button") }
    }
}
