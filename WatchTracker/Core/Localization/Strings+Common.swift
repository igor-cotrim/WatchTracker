import Foundation

extension Strings {
    // MARK: - Tabs

    enum Tab {
        static var home: String { String(localized: "tab.home") }
        static var watching: String { String(localized: "tab.watching") }
        static var discover: String { String(localized: "tab.discover") }
        static var ai: String { String(localized: "tab.ai") }
        static var profile: String { String(localized: "tab.profile") }
    }

    // MARK: - Common / Shared

    enum Common {
        static var retry: String { String(localized: "error.retry") }
        static var cancel: String { String(localized: "common.cancel") }
        static var ok: String { String(localized: "common.ok") }
        static var connectionError: String { String(localized: "error.connection") }
    }

    enum Card {
        static var unknownTitle: String { String(localized: "card.unknown_title") }
        static var accessibilityHint: String { String(localized: "card.accessibility.hint") }

        static func newEpisodes(_ count: Int) -> String {
            String(format: String(localized: "card.new_episodes"), count)
        }
    }

    // MARK: - Watchlist Status

    enum Status {
        static var planToWatch: String { String(localized: "status.plan_to_watch") }
        static var watching: String { String(localized: "status.watching") }
        static var completed: String { String(localized: "status.completed") }
    }

    // MARK: - Media Filter (Watchlist segmented picker)

    enum MediaFilter {
        static var all: String { String(localized: "media_filter.all") }
        static var movies: String { String(localized: "media_filter.movies") }
        static var tv: String { String(localized: "media_filter.tv") }
        static var anime: String { String(localized: "media_filter.anime") }
    }

    // MARK: - Media Type (badge labels)

    enum MediaTypeLabel {
        static var movie: String { String(localized: "media_type.movie") }
        static var series: String { String(localized: "media_type.series") }
    }
}
