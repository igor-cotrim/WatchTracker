import Foundation

extension Strings {
    // MARK: - Profile

    enum Profile {
        static var title: String { String(localized: "profile.title") }

        // Section headers
        static var statsSection: String { String(localized: "profile.stats") }
        static var preferencesSection: String { String(localized: "profile.preferences.section") }
        static var dataSection: String { String(localized: "profile.section.data") }
        static var supportSection: String { String(localized: "profile.section.support") }
        static var aboutSection: String { String(localized: "profile.about.section") }
        static var accountSection: String { String(localized: "profile.section.account") }

        // Account card
        static func memberSince(_ date: String) -> String {
            String(format: String(localized: "profile.member_since"), date)
        }

        // Appearance
        static var appearance: String { String(localized: "profile.appearance") }
        static var appearanceSystem: String { String(localized: "profile.appearance.system") }
        static var appearanceLight: String { String(localized: "profile.appearance.light") }
        static var appearanceDark: String { String(localized: "profile.appearance.dark") }
        static var language: String { String(localized: "profile.language") }

        // Stats
        static var statsLink: String { String(localized: "profile.stats.link") }
        static var statsEpisodes: String { String(localized: "profile.stats.episodes") }
        static var statsMovies: String { String(localized: "profile.stats.movies") }
        static var statsShowsCompleted: String { String(localized: "profile.stats.shows_completed") }
        static var statsAverageRating: String { String(localized: "profile.stats.average_rating") }
        static var statsTitlesRated: String { String(localized: "profile.stats.titles_rated") }
        static var statsAverageRatingEmpty: String { String(localized: "profile.stats.average_rating.empty") }
        static var statsShortEpisodes: String { String(localized: "profile.stats.short.episodes") }
        static var statsShortMovies: String { String(localized: "profile.stats.short.movies") }

        // Support
        static var feedback: String { String(localized: "profile.feedback") }
        static var rateApp: String { String(localized: "profile.rate_app") }

        // About
        static var tmdb: String { String(localized: "profile.about.tmdb") }
        static var tmdbAttribution: String { String(localized: "profile.about.tmdb_attribution") }
        static var privacyPolicy: String { String(localized: "profile.about.privacy_policy") }

        // Account actions
        static var signOut: String { String(localized: "profile.sign_out") }
        static var deleteAccount: String { String(localized: "profile.delete_account") }
        static var deleteAccountConfirmTitle: String { String(localized: "profile.delete_account.confirm.title") }
        static var deleteAccountConfirmMessage: String { String(localized: "profile.delete_account.confirm.message") }
        static var deleteAccountConfirmButton: String { String(localized: "profile.delete_account.confirm.button") }
        static var deleteAccountErrorTitle: String { String(localized: "profile.delete_account.error.title") }
        static var dangerZoneFooter: String { String(localized: "profile.danger_zone.footer") }
    }

    // MARK: - Feedback

    enum Feedback {
        static var bodyPlaceholder: String { String(localized: "profile.feedback.body_placeholder") }
        static var diagnosticsTitle: String { String(localized: "profile.feedback.diagnostics_title") }
        static var fieldApp: String { String(localized: "profile.feedback.field.app") }
        static var fieldSystem: String { String(localized: "profile.feedback.field.system") }
        static var fieldDevice: String { String(localized: "profile.feedback.field.device") }
        static var fieldLanguage: String { String(localized: "profile.feedback.field.language") }
        static var fieldAccount: String { String(localized: "profile.feedback.field.account") }
        static var errorTitle: String { String(localized: "profile.feedback.error.title") }

        static func subject(appName: String) -> String {
            String(format: String(localized: "profile.feedback.subject"), appName)
        }

        static func errorMessage(email: String) -> String {
            String(format: String(localized: "profile.feedback.error.message"), email)
        }
    }
}
