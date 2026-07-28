import Foundation

extension Strings {
    // MARK: - Discover

    enum Discover {
        static var title: String { String(localized: "discover.title") }
        static var searchPrompt: String { String(localized: "discover.search.prompt") }
        static var trending: String { String(localized: "discover.section.trending") }
        static var nowPlaying: String { String(localized: "discover.section.now_playing") }
        static var popular: String { String(localized: "discover.section.popular") }
        static var topRated: String { String(localized: "discover.section.top_rated") }
        static var upcoming: String { String(localized: "discover.section.upcoming") }
        static var anime: String { String(localized: "discover.section.anime") }
        static var genres: String { String(localized: "discover.section.genres") }
        static var providers: String { String(localized: "discover.section.providers") }
        static var suggestions: String { String(localized: "discover.search.suggestions") }
        static var recentSearches: String { String(localized: "discover.search.recent") }
        static var clear: String { String(localized: "discover.search.clear") }
        static var seeAll: String { String(localized: "discover.see_all") }
        static var tabMovies: String { String(localized: "discover.tab.movies") }
        static var tabTV: String { String(localized: "discover.tab.tv") }
        static var popularTV: String { String(localized: "discover.section.popular_tv") }
        static var topRatedTV: String { String(localized: "discover.section.top_rated_tv") }
        static var allProviders: String { String(localized: "discover.providers.all") }
        static var moodsTitle: String { String(localized: "discover.moods.title") }
        static var moodRelax: String { String(localized: "discover.mood.relax") }
        static var moodAdrenaline: String { String(localized: "discover.mood.adrenaline") }
        static var moodCry: String { String(localized: "discover.mood.cry") }
        static var moodScare: String { String(localized: "discover.mood.scare") }
        static var moodFeelGood: String { String(localized: "discover.mood.feel_good") }
        static var moodHeavy: String { String(localized: "discover.mood.heavy") }

        static func browseAccessibility(_ name: String) -> String {
            String(format: String(localized: "discover.browse.accessibility"), name)
        }

        static func newOnProvider(_ name: String) -> String {
            String(format: String(localized: "discover.section.new_on_provider"), name)
        }

        static func topTenOnProvider(_ name: String) -> String {
            String(format: String(localized: "discover.section.top_ten_on_provider"), name)
        }

        static func trendingOnProvider(_ name: String) -> String {
            String(format: String(localized: "discover.section.trending_on_provider"), name)
        }

        static func acclaimedOnProvider(_ name: String) -> String {
            String(format: String(localized: "discover.section.acclaimed_on_provider"), name)
        }

        static func topTenRank(_ rank: Int, title: String) -> String {
            String(format: String(localized: "discover.top_ten.rank_accessibility"), rank, title)
        }
    }

    // MARK: - Search Filter

    enum SearchFilter {
        static var all: String { String(localized: "search.filter.all") }
        static var movies: String { String(localized: "search.filter.movies") }
        static var tv: String { String(localized: "search.filter.tv") }
        static var anyYear: String { String(localized: "search.filter.any_year") }
        static var year: String { String(localized: "search.filter.year") }
    }
}
