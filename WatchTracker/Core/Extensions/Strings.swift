import Foundation

/// Typesafe access to all localised strings in Localizable.xcstrings.
///
/// Usage:
///   Text(Strings.Home.title)
///   Text(verbatim: Strings.Episode.label(number: 3, name: "Pilot"))
///
/// Keys match the xcstrings file exactly so Xcode's String Catalog editor
/// can track translation coverage automatically.
enum Strings {
    
    // MARK: - Tabs
    
    enum Tab {
        static var home: String        { String(localized: "tab.home") }
        static var watching: String    { String(localized: "tab.watching") }
        static var discover: String    { String(localized: "tab.discover") }
        static var profile: String     { String(localized: "tab.profile") }
    }
    
    // MARK: - Home
    
    enum Home {
        static var title: String              { String(localized: "home.title") }
        static var filterAll: String          { String(localized: "home.filter.all") }
        static var continueWatching: String   { String(localized: "home.continue_watching") }
    }
    
    // MARK: - Watchlist Status
    
    enum Status {
        static var planToWatch: String { String(localized: "status.plan_to_watch") }
        static var watching: String    { String(localized: "status.watching") }
        static var completed: String   { String(localized: "status.completed") }
    }
    
    // MARK: - Watchlist / Cards
    
    enum Watchlist {
        static var emptyTitle: String    { String(localized: "watchlist.empty.title") }
        static var emptySubtitle: String { String(localized: "watchlist.empty.subtitle") }
        static var emptyWatchingTitle: String    { String(localized: "watchlist.empty.watching.title") }
        static var emptyWatchingSubtitle: String { String(localized: "watchlist.empty.watching.subtitle") }
        static var emptyPlanTitle: String    { String(localized: "watchlist.empty.plan_to_watch.title") }
        static var emptyPlanSubtitle: String { String(localized: "watchlist.empty.plan_to_watch.subtitle") }
        static var emptyCompletedTitle: String    { String(localized: "watchlist.empty.completed.title") }
        static var emptyCompletedSubtitle: String { String(localized: "watchlist.empty.completed.subtitle") }
    }
    
    enum Card {
        static var unknownTitle: String  { String(localized: "card.unknown_title") }
        static var accessibilityHint: String { String(localized: "card.accessibility.hint") }
        
        static func newEpisodes(_ count: Int) -> String {
            String(format: String(localized: "card.new_episodes"), count)
        }
    }
    
    // MARK: - Common / Shared
    
    enum Common {
        static var retry: String { String(localized: "error.retry") }
    }
    
    // MARK: - Auth
    
    enum Auth {
        static var email: String      { String(localized: "auth.email") }
        static var password: String   { String(localized: "auth.password") }
        static var signIn: String     { String(localized: "auth.sign_in") }
        static var signUp: String     { String(localized: "auth.sign_up") }
        static var haveAccount: String  { String(localized: "auth.have_account") }
        static var noAccount: String    { String(localized: "auth.no_account") }
    }
    
    // MARK: - Profile
    
    enum Profile {
        static var title: String          { String(localized: "profile.title") }
        static var member: String         { String(localized: "profile.member") }
        static var stats: String          { String(localized: "profile.stats") }
        static var statsEpisodes: String       { String(localized: "profile.stats.episodes") }
        static var statsMovies: String         { String(localized: "profile.stats.movies") }
        static var statsWatchlist: String      { String(localized: "profile.stats.watchlist") }
        static var statsShows: String          { String(localized: "profile.stats.shows") }
        static var statsShowsCompleted: String { String(localized: "profile.stats.shows_completed") }
        static var signOut: String             { String(localized: "profile.sign_out") }
        
        static func totalHours(_ hours: Double) -> String {
            String(format: String(localized: "profile.stats.hours"), hours)
        }
    }
    
    // MARK: - Watching
    
    enum Watching {
        static var title: String          { String(localized: "watching.title") }
        static var emptyTitle: String     { String(localized: "watching.empty.title") }
        static var emptySubtitle: String  { String(localized: "watching.empty.subtitle") }
        static var markWatched: String    { String(localized: "watching.mark_watched") }
        static var viewDetails: String   { String(localized: "watching.view_details") }
        
        static func episodeLabel(season: Int, episode: Int) -> String {
            String(format: String(localized: "watching.episode_label"), season, episode)
        }
    }
    
    // MARK: - Upcoming

    enum Upcoming {
        static var tabWatching: String   { String(localized: "watching.tab.watching") }
        static var tabUpcoming: String   { String(localized: "watching.tab.upcoming") }
        static var emptyTitle: String    { String(localized: "upcoming.empty.title") }
        static var emptySubtitle: String { String(localized: "upcoming.empty.subtitle") }
        static var today: String         { String(localized: "upcoming.section.today") }
        static var tomorrow: String      { String(localized: "upcoming.section.tomorrow") }
        static var later: String         { String(localized: "upcoming.section.later") }

        static func daysAway(_ days: Int) -> String {
            String(format: String(localized: "upcoming.days_away"), days)
        }
    }

    // MARK: - Discover
    
    enum Discover {
        static var title: String           { String(localized: "discover.title") }
        static var searchPrompt: String    { String(localized: "discover.search.prompt") }
        static var trending: String        { String(localized: "discover.section.trending") }
        static var nowPlaying: String      { String(localized: "discover.section.now_playing") }
        static var popular: String         { String(localized: "discover.section.popular") }
        static var topRated: String        { String(localized: "discover.section.top_rated") }
        static var upcoming: String        { String(localized: "discover.section.upcoming") }
        static var anime: String           { String(localized: "discover.section.anime") }
        static var genres: String          { String(localized: "discover.section.genres") }
        static var providers: String       { String(localized: "discover.section.providers") }
        static var suggestions: String     { String(localized: "discover.search.suggestions") }
        static var recentSearches: String  { String(localized: "discover.search.recent") }
        static var clear: String           { String(localized: "discover.search.clear") }
        static var seeAll: String          { String(localized: "discover.see_all") }
        static var tabMovies: String       { String(localized: "discover.tab.movies") }
        static var tabTV: String           { String(localized: "discover.tab.tv") }
        static var popularTV: String       { String(localized: "discover.section.popular_tv") }
        static var topRatedTV: String      { String(localized: "discover.section.top_rated_tv") }
        
        static func browseAccessibility(_ name: String) -> String {
            String(format: String(localized: "discover.browse.accessibility"), name)
        }
    }
    
    // MARK: - Media Filter (Watchlist segmented picker)
    
    enum MediaFilter {
        static var all: String    { String(localized: "media_filter.all") }
        static var movies: String { String(localized: "media_filter.movies") }
        static var tv: String     { String(localized: "media_filter.tv") }
        static var anime: String  { String(localized: "media_filter.anime") }
    }
    
    // MARK: - Search Filter
    
    enum SearchFilter {
        static var all: String     { String(localized: "search.filter.all") }
        static var movies: String  { String(localized: "search.filter.movies") }
        static var tv: String      { String(localized: "search.filter.tv") }
        static var anyYear: String { String(localized: "search.filter.any_year") }
        static var year: String    { String(localized: "search.filter.year") }
    }
    
    // MARK: - Detail
    
    enum Detail {
        static var watchlistAdd: String     { String(localized: "detail.watchlist.add") }
        static var watchlistRemove: String  { String(localized: "detail.watchlist.remove") }
        static var watchlistWatched: String { String(localized: "detail.watchlist.watched") }
        static var watchlistAccessibilityAdd: String  { String(localized: "detail.watchlist.accessibility.add") }
        static var watchlistAccessibilityHint: String { String(localized: "detail.watchlist.accessibility.hint") }
        
        static func watchlistAccessibilityOnList(_ status: String) -> String {
            String(format: String(localized: "detail.watchlist.accessibility.on_list"), status)
        }
        
        static var seasons: String            { String(localized: "detail.seasons.title") }
        static var synopsis: String           { String(localized: "detail.synopsis.title") }
        static var cast: String               { String(localized: "detail.cast.title") }
        static var whereToWatch: String       { String(localized: "detail.where_to_watch.title") }
        static var whereToWatchUnavailable: String { String(localized: "detail.where_to_watch.unavailable") }
        
        static func seasonEpisodesCount(_ count: Int) -> String {
            String(format: String(localized: "detail.season.episodes_count"), count)
        }

        static var seasonMarkWatched: String   { String(localized: "detail.season.mark_watched") }
        static var seasonUnmarkWatched: String { String(localized: "detail.season.unmark_watched") }
    }
    
    // MARK: - Episode
    
    enum Episode {
        static var accessibilityWatched: String       { String(localized: "episode.accessibility.watched") }
        static var accessibilityNotWatched: String    { String(localized: "episode.accessibility.not_watched") }
        static var accessibilityMarkWatched: String   { String(localized: "episode.accessibility.mark_watched") }
        static var accessibilityMarkUnwatched: String { String(localized: "episode.accessibility.mark_unwatched") }
        static var accessibilityNotReleased: String   { String(localized: "episode.accessibility.not_released") }
        
        static func label(number: Int, name: String) -> String {
            String(format: String(localized: "episode.label"), number, name)
        }
        
        static func accessibilityLabel(number: Int, name: String) -> String {
            String(format: String(localized: "episode.accessibility.label"), number, name)
        }
    }
}
