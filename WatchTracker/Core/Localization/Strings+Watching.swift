import Foundation

extension Strings {
    // MARK: - Watching

    enum Watching {
        static var title: String { String(localized: "watching.title") }
        static var emptyTitle: String { String(localized: "watching.empty.title") }
        static var emptySubtitle: String { String(localized: "watching.empty.subtitle") }
        static var markWatched: String { String(localized: "watching.mark_watched") }
        static var viewDetails: String { String(localized: "watching.view_details") }

        static func episodeLabel(season: Int, episode: Int) -> String {
            String(format: String(localized: "watching.episode_label"), season, episode)
        }
    }

    // MARK: - Upcoming

    enum Upcoming {
        static var tabWatching: String { String(localized: "watching.tab.watching") }
        static var tabUpcoming: String { String(localized: "watching.tab.upcoming") }
        static var emptyTitle: String { String(localized: "upcoming.empty.title") }
        static var emptySubtitle: String { String(localized: "upcoming.empty.subtitle") }
        static var today: String { String(localized: "upcoming.section.today") }
        static var tomorrow: String { String(localized: "upcoming.section.tomorrow") }
        static var later: String { String(localized: "upcoming.section.later") }

        static func daysAway(_ days: Int) -> String {
            String(format: String(localized: "upcoming.days_away"), days)
        }
    }

    // MARK: - Episode

    enum Episode {
        static var accessibilityWatched: String { String(localized: "episode.accessibility.watched") }
        static var accessibilityNotWatched: String { String(localized: "episode.accessibility.not_watched") }
        static var accessibilityMarkWatched: String { String(localized: "episode.accessibility.mark_watched") }
        static var accessibilityMarkUnwatched: String { String(localized: "episode.accessibility.mark_unwatched") }
        static var accessibilityNotReleased: String { String(localized: "episode.accessibility.not_released") }

        static func label(number: Int, name: String) -> String {
            String(format: String(localized: "episode.label"), number, name)
        }

        static func accessibilityLabel(number: Int, name: String) -> String {
            String(format: String(localized: "episode.accessibility.label"), number, name)
        }
    }
}
