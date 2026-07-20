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
        static var home: String { String(localized: "tab.home") }
        static var watching: String { String(localized: "tab.watching") }
        static var discover: String { String(localized: "tab.discover") }
        static var ai: String { String(localized: "tab.ai") }
        static var profile: String { String(localized: "tab.profile") }
    }
    
    // MARK: - Home
    
    enum Home {
        static var title: String { String(localized: "home.title") }
        static var filterAll: String { String(localized: "home.filter.all") }
        static var continueWatching: String { String(localized: "home.continue_watching") }
    }
    
    // MARK: - Watchlist Status
    
    enum Status {
        static var planToWatch: String { String(localized: "status.plan_to_watch") }
        static var watching: String { String(localized: "status.watching") }
        static var completed: String { String(localized: "status.completed") }
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
    
    enum Card {
        static var unknownTitle: String { String(localized: "card.unknown_title") }
        static var accessibilityHint: String { String(localized: "card.accessibility.hint") }
        
        static func newEpisodes(_ count: Int) -> String {
            String(format: String(localized: "card.new_episodes"), count)
        }
    }
    
    // MARK: - Common / Shared
    
    enum Common {
        static var retry: String { String(localized: "error.retry") }
        static var cancel: String { String(localized: "common.cancel") }
        static var ok: String { String(localized: "common.ok") }
    }
    
    // MARK: - Auth
    
    enum Auth {
        static var name: String { String(localized: "auth.name") }
        static var namePlaceholder: String { String(localized: "auth.name_placeholder") }
        static var email: String { String(localized: "auth.email") }
        static var password: String { String(localized: "auth.password") }
        static var signIn: String { String(localized: "auth.sign_in") }
        static var signUp: String { String(localized: "auth.sign_up") }
        static var haveAccount: String { String(localized: "auth.have_account") }
        static var noAccount: String { String(localized: "auth.no_account") }
        static var haveAccountPrefix: String { String(localized: "auth.have_account_prefix") }
        static var noAccountPrefix: String { String(localized: "auth.no_account_prefix") }
        static var trackYourShows: String { String(localized: "auth.track_your_shows") }

        static var welcomeTitle: String { String(localized: "auth.welcome_title") }
        static var welcomeSubtitle: String { String(localized: "auth.welcome_subtitle") }
        static var registerTitle: String { String(localized: "auth.register_title") }
        static var registerSubtitle: String { String(localized: "auth.register_subtitle") }

        static var passwordReqMinLength: String { String(localized: "auth.password_req_min_length") }
        static var passwordReqUppercase: String { String(localized: "auth.password_req_uppercase") }
        static var passwordReqNumber: String { String(localized: "auth.password_req_number") }

        static var forgotPassword: String { String(localized: "auth.forgot_password") }
        static var forgotPasswordTitle: String { String(localized: "auth.forgot_password_title") }
        static var forgotPasswordMessage: String { String(localized: "auth.forgot_password_message") }
        static var sendCode: String { String(localized: "auth.send_code") }
        static var resetCodeInstructions: String { String(localized: "auth.reset_code_instructions") }
        static var resetCodePlaceholder: String { String(localized: "auth.reset_code_placeholder") }
        static var newPasswordPlaceholder: String { String(localized: "auth.new_password_placeholder") }
        static var resetPasswordButton: String { String(localized: "auth.reset_password_button") }
        static var passwordUpdated: String { String(localized: "auth.password_updated") }
        static var passwordUpdatedHint: String { String(localized: "auth.password_updated_hint") }
    }
    
    // MARK: - Profile
    
    enum Profile {
        static var title: String { String(localized: "profile.title") }
        static var member: String { String(localized: "profile.member") }
        static var stats: String { String(localized: "profile.stats") }
        static var statsEpisodes: String { String(localized: "profile.stats.episodes") }
        static var statsMovies: String { String(localized: "profile.stats.movies") }
        static var statsWatchlist: String { String(localized: "profile.stats.watchlist") }
        static var statsShows: String { String(localized: "profile.stats.shows") }
        static var statsShowsCompleted: String { String(localized: "profile.stats.shows_completed") }
        static var signOut: String { String(localized: "profile.sign_out") }
        static var aboutSection: String { String(localized: "profile.about.section") }
        static var tmdbAttribution: String { String(localized: "profile.about.tmdb_attribution") }
        static var privacyPolicy: String { String(localized: "profile.about.privacy_policy") }
        static var deleteAccount: String { String(localized: "profile.delete_account") }
        static var deleteAccountConfirmTitle: String { String(localized: "profile.delete_account.confirm.title") }
        static var deleteAccountConfirmMessage: String { String(localized: "profile.delete_account.confirm.message") }
        static var deleteAccountConfirmButton: String { String(localized: "profile.delete_account.confirm.button") }
        static var deleteAccountErrorTitle: String { String(localized: "profile.delete_account.error.title") }
        static var dangerZoneSection: String { String(localized: "profile.danger_zone.section") }
        static var dangerZoneFooter: String { String(localized: "profile.danger_zone.footer") }
        static var preferencesSection: String { String(localized: "profile.preferences.section") }
        static var language: String { String(localized: "profile.preferences.language") }
        static var languageEnglish: String { String(localized: "profile.preferences.language.english") }
        static var languagePortuguese: String { String(localized: "profile.preferences.language.portuguese") }
        
        static func totalHours(_ hours: Double) -> String {
            String(format: String(localized: "profile.stats.hours"), hours)
        }
    }
    
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

    // MARK: - Search Filter

    enum SearchFilter {
        static var all: String { String(localized: "search.filter.all") }
        static var movies: String { String(localized: "search.filter.movies") }
        static var tv: String { String(localized: "search.filter.tv") }
        static var anyYear: String { String(localized: "search.filter.any_year") }
        static var year: String { String(localized: "search.filter.year") }
    }
    
    // MARK: - Detail
    
    enum Detail {
        static var watchlistAdd: String { String(localized: "detail.watchlist.add") }
        static var watchlistRemove: String { String(localized: "detail.watchlist.remove") }
        static var watchlistWatched: String { String(localized: "detail.watchlist.watched") }
        static var watchlistAccessibilityAdd: String { String(localized: "detail.watchlist.accessibility.add") }
        static var watchlistAccessibilityHint: String { String(localized: "detail.watchlist.accessibility.hint") }
        static var seasons: String { String(localized: "detail.seasons.title") }
        static var synopsis: String { String(localized: "detail.synopsis.title") }
        static var cast: String { String(localized: "detail.cast.title") }
        static var whereToWatch: String { String(localized: "detail.where_to_watch.title") }
        static var recommendations: String { String(localized: "detail.recommendations.title") }
        static var whereToWatchUnavailable: String { String(localized: "detail.where_to_watch.unavailable") }
        static var openInProviderHint: String { String(localized: "detail.where_to_watch.open_in_provider_hint") }
        static var seasonMarkWatched: String { String(localized: "detail.season.mark_watched") }
        static var seasonUnmarkWatched: String { String(localized: "detail.season.unmark_watched") }
        
        static func watchlistAccessibilityOnList(_ status: String) -> String {
            String(format: String(localized: "detail.watchlist.accessibility.on_list"), status)
        }
        
        static func seasonEpisodesCount(_ count: Int) -> String {
            String(format: String(localized: "detail.season.episodes_count"), count)
        }
    }

    // MARK: - Rating

    enum Rating {
        static var yourRating: String { String(localized: "rating.your_rating") }
        static var tapToRate: String { String(localized: "rating.tap_to_rate") }
        static var startSeries: String { String(localized: "rating.start_series") }
        static var share: String { String(localized: "rating.share") }
        static var shareAccessibility: String { String(localized: "rating.share.accessibility") }

        /// Playful caption keyed to the 1–10 rating, shown next to the stars and on the share card.
        static func mood(forRating rating: Int) -> String {
            switch rating {
            case ...2: return String(localized: "rating.mood.awful")
            case 3...4: return String(localized: "rating.mood.meh")
            case 5...6: return String(localized: "rating.mood.decent")
            case 7...8: return String(localized: "rating.mood.great")
            default: return String(localized: "rating.mood.masterpiece")
            }
        }
    }

    // MARK: - Share

    enum Share {
        static var downloadCTA: String { String(localized: "share.download_cta") }
    }

    
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

    // MARK: - Notifications

    enum Notifications {
        static var sectionTitle: String { String(localized: "notifications.section_title") }
        static var episodeReminders: String { String(localized: "notifications.episode_reminders") }
        static var newEpisodeBody: String { String(localized: "notifications.new_episode_body") }
        static var newSeasonSubtitle: String { String(localized: "notifications.new_season_subtitle") }
        static func newSeasonBody(season: Int) -> String {
            String(format: String(localized: "notifications.new_season_body"), season)
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
