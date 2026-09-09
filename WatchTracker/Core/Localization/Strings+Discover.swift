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

    // MARK: - Discover Filter

    enum DiscoverFilter {
        static var title: String { String(localized: "discover.filter.title") }
        static var button: String { String(localized: "discover.filter.button") }
        static var apply: String { String(localized: "discover.filter.apply") }
        static var clear: String { String(localized: "discover.filter.clear") }
        static var sectionType: String { String(localized: "discover.filter.section.type") }
        static var sectionGenres: String { String(localized: "discover.filter.section.genres") }
        static var sectionSort: String { String(localized: "discover.filter.section.sort") }
        static var sectionProviders: String { String(localized: "discover.filter.section.providers") }
        static var sectionDecade: String { String(localized: "discover.filter.section.decade") }
        static var sortPopularity: String { String(localized: "discover.filter.sort.popularity") }
        static var sortRating: String { String(localized: "discover.filter.sort.rating") }
        static var sortNewest: String { String(localized: "discover.filter.sort.newest") }
        static var sortTitle: String { String(localized: "discover.filter.sort.title") }
        static var anyDecade: String { String(localized: "discover.filter.decade.any") }
        static var before1980: String { String(localized: "discover.filter.decade.before_1980") }
        static var resultsTitle: String { String(localized: "discover.filter.results_title") }
        static var empty: String { String(localized: "discover.filter.empty") }
        static var emptyAction: String { String(localized: "discover.filter.empty_action") }

        static func decade(_ startYear: Int) -> String {
            String(format: String(localized: "discover.filter.decade.value"), startYear)
        }

        static func buttonAccessibility(activeCount: Int) -> String {
            String(format: String(localized: "discover.filter.accessibility_count"), activeCount)
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
