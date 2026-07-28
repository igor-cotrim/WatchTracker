import Foundation

extension Strings {
    // MARK: - AI

    enum AI {
        static var title: String { String(localized: "ai.title") }
        static var loading: String { String(localized: "ai.loading") }
        static var emptyTitle: String { String(localized: "ai.empty.title") }
        static var emptySubtitle: String { String(localized: "ai.empty.subtitle") }
        static var emptyWatchlistTitle: String { String(localized: "ai.empty_watchlist.title") }
        static var emptyWatchlistSubtitle: String { String(localized: "ai.empty_watchlist.subtitle") }
        static var unavailableNotEligible: String { String(localized: "ai.unavailable.not_eligible") }
        static var unavailableNotEligibleSubtitle: String { String(localized: "ai.unavailable.not_eligible.subtitle") }
        static var unavailableNotEnabled: String { String(localized: "ai.unavailable.not_enabled") }
        static var unavailableNotEnabledSubtitle: String { String(localized: "ai.unavailable.not_enabled.subtitle") }
        static var unavailableNotReady: String { String(localized: "ai.unavailable.not_ready") }
        static var unavailableNotReadySubtitle: String{ String(localized: "ai.unavailable.not_ready.subtitle") }
        static var promptPlaceholder: String { String(localized: "ai.prompt.placeholder") }
        static var idleTitle: String { String(localized: "ai.idle.title") }
        static var idleSubtitle: String { String(localized: "ai.idle.subtitle") }
        static var exampleAnime: String { String(localized: "ai.example.anime") }
        static var exampleMovie: String { String(localized: "ai.example.movie") }
        static var exampleMood: String { String(localized: "ai.example.mood") }
    }
}
