import Foundation
import Testing
@testable import WatchTracker

/// Touches every no-argument `Strings` accessor and asserts it resolves to real copy.
///
/// `String(localized:)` silently returns the key itself when the catalog has no entry,
/// so a typo or a key added to Swift but never to Localizable.xcstrings ships as raw
/// text like "profile.sign_out" in the UI. Nothing else in the suite would catch that:
/// before this test, eight of the twelve `Strings+<Feature>` files sat under 40%
/// coverage and three were at 0%.
///
/// Most parameterised accessors are covered in `StringsTests`; the seven it did not
/// reach are at the bottom of this file.
@Suite("Strings catalog", .tags(.pure))
struct StringsCatalogTests {

    @Test(arguments: [
        (Strings.AI.title, "ai.title"),
        (Strings.AI.loading, "ai.loading"),
        (Strings.AI.emptyTitle, "ai.empty.title"),
        (Strings.AI.emptySubtitle, "ai.empty.subtitle"),
        (Strings.AI.unavailableNotEligible, "ai.unavailable.not_eligible"),
        (Strings.AI.unavailableNotEligibleSubtitle, "ai.unavailable.not_eligible.subtitle"),
        (Strings.AI.unavailableNotEnabled, "ai.unavailable.not_enabled"),
        (Strings.AI.unavailableNotEnabledSubtitle, "ai.unavailable.not_enabled.subtitle"),
        (Strings.AI.unavailableNotReady, "ai.unavailable.not_ready"),
        (Strings.AI.promptPlaceholder, "ai.prompt.placeholder"),
        (Strings.AI.idleTitle, "ai.idle.title"),
        (Strings.AI.idleSubtitle, "ai.idle.subtitle"),
        (Strings.AI.exampleAnime, "ai.example.anime"),
        (Strings.AI.exampleMovie, "ai.example.movie"),
        (Strings.AI.exampleMood, "ai.example.mood")
    ])
    func `a i keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Auth.name, "auth.name"),
        (Strings.Auth.namePlaceholder, "auth.name_placeholder"),
        (Strings.Auth.email, "auth.email"),
        (Strings.Auth.password, "auth.password"),
        (Strings.Auth.signIn, "auth.sign_in"),
        (Strings.Auth.signUp, "auth.sign_up"),
        (Strings.Auth.haveAccountPrefix, "auth.have_account_prefix"),
        (Strings.Auth.noAccountPrefix, "auth.no_account_prefix"),
        (Strings.Auth.trackYourShows, "auth.track_your_shows"),
        (Strings.Auth.welcomeTitle, "auth.welcome_title"),
        (Strings.Auth.welcomeSubtitle, "auth.welcome_subtitle"),
        (Strings.Auth.registerTitle, "auth.register_title"),
        (Strings.Auth.registerSubtitle, "auth.register_subtitle"),
        (Strings.Auth.passwordReqMinLength, "auth.password_req_min_length"),
        (Strings.Auth.passwordReqUppercase, "auth.password_req_uppercase"),
        (Strings.Auth.passwordReqNumber, "auth.password_req_number"),
        (Strings.Auth.forgotPassword, "auth.forgot_password"),
        (Strings.Auth.forgotPasswordTitle, "auth.forgot_password_title"),
        (Strings.Auth.forgotPasswordMessage, "auth.forgot_password_message"),
        (Strings.Auth.sendCode, "auth.send_code"),
        (Strings.Auth.resetCodeInstructions, "auth.reset_code_instructions"),
        (Strings.Auth.resetCodePlaceholder, "auth.reset_code_placeholder"),
        (Strings.Auth.newPasswordPlaceholder, "auth.new_password_placeholder"),
        (Strings.Auth.resetPasswordButton, "auth.reset_password_button"),
        (Strings.Auth.passwordUpdated, "auth.password_updated"),
        (Strings.Auth.passwordUpdatedHint, "auth.password_updated_hint"),
        (Strings.Auth.sessionExpired, "auth.session_expired")
    ])
    func `auth keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Tab.home, "tab.home"),
        (Strings.Tab.watching, "tab.watching"),
        (Strings.Tab.discover, "tab.discover"),
        (Strings.Tab.ai, "tab.ai"),
        (Strings.Tab.profile, "tab.profile")
    ])
    func `tab keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Common.retry, "error.retry"),
        (Strings.Common.cancel, "common.cancel"),
        (Strings.Common.ok, "common.ok"),
        (Strings.Common.connectionError, "error.connection")
    ])
    func `common keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Errors.unauthorized, "error.unauthorized"),
        (Strings.Errors.notFound, "error.not_found"),
        (Strings.Errors.server, "error.server"),
        (Strings.Errors.rateLimited, "error.rate_limited"),
        (Strings.Errors.decoding, "error.decoding"),
        (Strings.Errors.unknown, "error.unknown")
    ])
    func `errors keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Card.unknownTitle, "card.unknown_title"),
        (Strings.Card.accessibilityHint, "card.accessibility.hint")
    ])
    func `card keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Status.planToWatch, "status.plan_to_watch"),
        (Strings.Status.watching, "status.watching"),
        (Strings.Status.completed, "status.completed")
    ])
    func `status keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.MediaFilter.all, "media_filter.all"),
        (Strings.MediaFilter.movies, "media_filter.movies"),
        (Strings.MediaFilter.tv, "media_filter.tv"),
        (Strings.MediaFilter.anime, "media_filter.anime")
    ])
    func `media filter keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.MediaTypeLabel.movie, "media_type.movie"),
        (Strings.MediaTypeLabel.series, "media_type.series")
    ])
    func `media type label keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Data.title, "data.title"),
        (Strings.Data.exportSection, "data.export_section"),
        (Strings.Data.importSection, "data.import_section")
    ])
    func `data keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Detail.watchlistAdd, "detail.watchlist.add"),
        (Strings.Detail.watchlistRemove, "detail.watchlist.remove"),
        (Strings.Detail.watchlistWatched, "detail.watchlist.watched"),
        (Strings.Detail.watchlistAccessibilityAdd, "detail.watchlist.accessibility.add"),
        (Strings.Detail.watchlistAccessibilityHint, "detail.watchlist.accessibility.hint"),
        (Strings.Detail.seasons, "detail.seasons.title"),
        (Strings.Detail.synopsis, "detail.synopsis.title"),
        (Strings.Detail.cast, "detail.cast.title"),
        (Strings.Detail.whereToWatch, "detail.where_to_watch.title"),
        (Strings.Detail.recommendations, "detail.recommendations.title"),
        (Strings.Detail.whereToWatchUnavailable, "detail.where_to_watch.unavailable"),
        (Strings.Detail.openInProviderHint, "detail.where_to_watch.open_in_provider_hint"),
        (Strings.Detail.seasonMarkWatched, "detail.season.mark_watched"),
        (Strings.Detail.seasonUnmarkWatched, "detail.season.unmark_watched")
    ])
    func `detail keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Rating.yourRating, "rating.your_rating"),
        (Strings.Rating.tapToRate, "rating.tap_to_rate"),
        (Strings.Rating.startSeries, "rating.start_series"),
        (Strings.Rating.share, "rating.share"),
        (Strings.Rating.shareAccessibility, "rating.share.accessibility"),
        (Strings.Rating.remove, "rating.remove"),
        (Strings.Rating.removeAccessibility, "rating.remove.accessibility"),
        (Strings.Rating.removeConfirmTitle, "rating.remove.confirm_title")
    ])
    func `rating keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Share.downloadCTA, "share.download_cta")
    ])
    func `share keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Discover.title, "discover.title"),
        (Strings.Discover.searchPrompt, "discover.search.prompt"),
        (Strings.Discover.trending, "discover.section.trending"),
        (Strings.Discover.nowPlaying, "discover.section.now_playing"),
        (Strings.Discover.popular, "discover.section.popular"),
        (Strings.Discover.topRated, "discover.section.top_rated"),
        (Strings.Discover.upcoming, "discover.section.upcoming"),
        (Strings.Discover.anime, "discover.section.anime"),
        (Strings.Discover.genres, "discover.section.genres"),
        (Strings.Discover.providers, "discover.section.providers"),
        (Strings.Discover.suggestions, "discover.search.suggestions"),
        (Strings.Discover.recentSearches, "discover.search.recent"),
        (Strings.Discover.clear, "discover.search.clear"),
        (Strings.Discover.seeAll, "discover.see_all"),
        (Strings.Discover.allProviders, "discover.providers.all"),
        (Strings.Discover.moodsTitle, "discover.moods.title"),
        (Strings.Discover.moodRelax, "discover.mood.relax"),
        (Strings.Discover.moodAdrenaline, "discover.mood.adrenaline"),
        (Strings.Discover.moodCry, "discover.mood.cry"),
        (Strings.Discover.moodScare, "discover.mood.scare"),
        (Strings.Discover.moodFeelGood, "discover.mood.feel_good"),
        (Strings.Discover.moodHeavy, "discover.mood.heavy")
    ])
    func `discover keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.SearchFilter.all, "search.filter.all"),
        (Strings.SearchFilter.movies, "search.filter.movies"),
        (Strings.SearchFilter.tv, "search.filter.tv"),
        (Strings.SearchFilter.anyYear, "search.filter.any_year"),
        (Strings.SearchFilter.year, "search.filter.year")
    ])
    func `search filter keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Export.action, "export.action"),
        (Strings.Export.exporting, "export.exporting"),
        (Strings.Export.resultsTitle, "export.results_title"),
        (Strings.Export.share, "export.share"),
        (Strings.Export.errorEmpty, "export.error_empty"),
        (Strings.Export.format, "export.format"),
        (Strings.Export.formatWatchTracker, "export.format_watchtracker"),
        (Strings.Export.formatWatchTrackerHint, "export.format_watchtracker_hint"),
        (Strings.Export.formatLetterboxd, "export.format_letterboxd"),
        (Strings.Export.formatLetterboxdHint, "export.format_letterboxd_hint")
    ])
    func `export keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Home.title, "home.title"),
        (Strings.Home.continueWatching, "home.continue_watching")
    ])
    func `home keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Watchlist.emptyTitle, "watchlist.empty.title"),
        (Strings.Watchlist.emptySubtitle, "watchlist.empty.subtitle"),
        (Strings.Watchlist.emptyWatchingTitle, "watchlist.empty.watching.title"),
        (Strings.Watchlist.emptyWatchingSubtitle, "watchlist.empty.watching.subtitle"),
        (Strings.Watchlist.emptyPlanTitle, "watchlist.empty.plan_to_watch.title"),
        (Strings.Watchlist.emptyPlanSubtitle, "watchlist.empty.plan_to_watch.subtitle"),
        (Strings.Watchlist.emptyCompletedTitle, "watchlist.empty.completed.title"),
        (Strings.Watchlist.emptyCompletedSubtitle, "watchlist.empty.completed.subtitle"),
        (Strings.Watchlist.discoverButton, "watchlist.empty.discover_button")
    ])
    func `watchlist keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Import.title, "import.title"),
        (Strings.Import.pickFile, "import.pick_file"),
        (Strings.Import.pickFileHint, "import.pick_file_hint"),
        (Strings.Import.importing, "import.importing"),
        (Strings.Import.resultsTitle, "import.results_title"),
        (Strings.Import.resultMatched, "import.result_matched"),
        (Strings.Import.resultWatchlist, "import.result_watchlist"),
        (Strings.Import.resultRatings, "import.result_ratings"),
        (Strings.Import.resultEpisodes, "import.result_episodes"),
        (Strings.Import.unmatchedTitle, "import.unmatched_title"),
        (Strings.Import.errorEmpty, "import.error_empty")
    ])
    func `import keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Notifications.episodeReminders, "notifications.episode_reminders"),
        (Strings.Notifications.newSeasonSubtitle, "notifications.new_season_subtitle")
    ])
    func `notifications keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Profile.title, "profile.title"),
        (Strings.Profile.statsSection, "profile.stats"),
        (Strings.Profile.preferencesSection, "profile.preferences.section"),
        (Strings.Profile.dataSection, "profile.section.data"),
        (Strings.Profile.supportSection, "profile.section.support"),
        (Strings.Profile.aboutSection, "profile.about.section"),
        (Strings.Profile.accountSection, "profile.section.account"),
        (Strings.Profile.appearance, "profile.appearance"),
        (Strings.Profile.appearanceSystem, "profile.appearance.system"),
        (Strings.Profile.appearanceLight, "profile.appearance.light"),
        (Strings.Profile.appearanceDark, "profile.appearance.dark"),
        (Strings.Profile.language, "profile.language"),
        (Strings.Profile.statsLink, "profile.stats.link"),
        (Strings.Profile.statsEpisodes, "profile.stats.episodes"),
        (Strings.Profile.statsMovies, "profile.stats.movies"),
        (Strings.Profile.statsShowsCompleted, "profile.stats.shows_completed"),
        (Strings.Profile.statsAverageRating, "profile.stats.average_rating"),
        (Strings.Profile.statsTitlesRated, "profile.stats.titles_rated"),
        (Strings.Profile.statsAverageRatingEmpty, "profile.stats.average_rating.empty"),
        (Strings.Profile.statsShortEpisodes, "profile.stats.short.episodes"),
        (Strings.Profile.statsShortMovies, "profile.stats.short.movies"),
        (Strings.Profile.feedback, "profile.feedback"),
        (Strings.Profile.rateApp, "profile.rate_app"),
        (Strings.Profile.tmdb, "profile.about.tmdb"),
        (Strings.Profile.tmdbAttribution, "profile.about.tmdb_attribution"),
        (Strings.Profile.privacyPolicy, "profile.about.privacy_policy"),
        (Strings.Profile.signOut, "profile.sign_out"),
        (Strings.Profile.deleteAccount, "profile.delete_account"),
        (Strings.Profile.deleteAccountConfirmTitle, "profile.delete_account.confirm.title"),
        (Strings.Profile.deleteAccountConfirmMessage, "profile.delete_account.confirm.message"),
        (Strings.Profile.deleteAccountConfirmButton, "profile.delete_account.confirm.button"),
        (Strings.Profile.deleteAccountErrorTitle, "profile.delete_account.error.title"),
        (Strings.Profile.dangerZoneFooter, "profile.danger_zone.footer")
    ])
    func `profile keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Feedback.bodyPlaceholder, "profile.feedback.body_placeholder"),
        (Strings.Feedback.diagnosticsTitle, "profile.feedback.diagnostics_title"),
        (Strings.Feedback.fieldApp, "profile.feedback.field.app"),
        (Strings.Feedback.fieldSystem, "profile.feedback.field.system"),
        (Strings.Feedback.fieldDevice, "profile.feedback.field.device"),
        (Strings.Feedback.fieldLanguage, "profile.feedback.field.language"),
        (Strings.Feedback.fieldAccount, "profile.feedback.field.account"),
        (Strings.Feedback.errorTitle, "profile.feedback.error.title")
    ])
    func `feedback keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Watching.title, "watching.title"),
        (Strings.Watching.emptyTitle, "watching.empty.title"),
        (Strings.Watching.emptySubtitle, "watching.empty.subtitle"),
        (Strings.Watching.markWatched, "watching.mark_watched"),
        (Strings.Watching.viewDetails, "watching.view_details")
    ])
    func `watching keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Upcoming.tabWatching, "watching.tab.watching"),
        (Strings.Upcoming.tabUpcoming, "watching.tab.upcoming"),
        (Strings.Upcoming.emptyTitle, "upcoming.empty.title"),
        (Strings.Upcoming.emptySubtitle, "upcoming.empty.subtitle"),
        (Strings.Upcoming.today, "upcoming.section.today"),
        (Strings.Upcoming.tomorrow, "upcoming.section.tomorrow"),
        (Strings.Upcoming.later, "upcoming.section.later")
    ])
    func `upcoming keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    @Test(arguments: [
        (Strings.Episode.accessibilityWatched, "episode.accessibility.watched"),
        (Strings.Episode.accessibilityNotWatched, "episode.accessibility.not_watched"),
        (Strings.Episode.accessibilityMarkWatched, "episode.accessibility.mark_watched"),
        (Strings.Episode.accessibilityMarkUnwatched, "episode.accessibility.mark_unwatched"),
        (Strings.Episode.accessibilityNotReleased, "episode.accessibility.not_released")
    ])
    func `episode keys resolve`(value: String, key: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(!value.isEmpty, "Empty catalog entry for \(key)")
    }

    // MARK: - Parameterised accessors not reached by StringsTests

    /// These interpolate through `String(format:)`, so a missing catalog entry shows up
    /// as the bare key *and* silently drops the substitution.
    @Test(arguments: [
        (Strings.Detail.watchlistAccessibilityOnList("Watching"), "detail.watchlist.accessibility.on_list", "Watching"),
        (Strings.Discover.browseAccessibility("Netflix"), "discover.browse.accessibility", "Netflix"),
        (Strings.Profile.memberSince("Jan 2026"), "profile.member_since", "Jan 2026"),
        (Strings.Feedback.errorMessage(email: "a@b.com"), "profile.feedback.error.message", "a@b.com")
    ])
    func `string-substituted accessors resolve and interpolate`(
        value: String, key: String, substitution: String
    ) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(value.contains(substitution), "\(key) dropped its substitution")
    }

    @Test(arguments: [
        (Strings.Export.fileRows(42), "export.file_rows", "42"),
        (Strings.Export.unresolved(7), "export.unresolved", "7")
    ])
    func `count accessors resolve and interpolate`(value: String, key: String, count: String) {
        #expect(value != key, "Missing catalog entry for \(key)")
        #expect(value.contains(count), "\(key) dropped its count")
    }

    @Test func `episode accessibility label carries both number and name`() {
        let value = Strings.Episode.accessibilityLabel(number: 3, name: "Pilot")
        #expect(value != "episode.accessibility.label")
        #expect(value.contains("3"))
        #expect(value.contains("Pilot"))
    }
}
