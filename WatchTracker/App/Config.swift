import Foundation

// MARK: - App Configuration
//
// Values are injected at build time: Config/Base.xcconfig (shared) plus
// Config/Debug.xcconfig or Config/Release.xcconfig (per configuration) are mapped
// into the app's Info.plist by Config/Info.plist, and read back here.
//
// To change a value, edit the xcconfig — never hardcode it below.

enum Config {
    /// Supabase project URL — safe for client distribution.
    static let supabaseURL: URL = Bundle.main.configurationURL(for: "SUPABASE_URL")

    /// Publishable (anon) key only. RLS enforces authorization server-side.
    /// NEVER place the service_role / secret key here — it bypasses RLS.
    static let supabasePublishableKey: String = Bundle.main.configurationValue(for: "SUPABASE_PUBLISHABLE_KEY")

    /// Points at the local backend in Debug and at Cloud Run in Release.
    static let apiBaseURL: URL = Bundle.main.configurationURL(for: "API_BASE_URL")

    // MARK: - Analytics (PostHog)

    /// PostHog project API key — safe for client distribution (write-only ingestion key).
    static let posthogAPIKey: String = Bundle.main.configurationValue(for: "POSTHOG_API_KEY")

    /// PostHog ingestion host.
    static let posthogHost: String = Bundle.main.configurationValue(for: "POSTHOG_HOST")

    // MARK: - Links & Support

    /// App Store identifier, used to build the review link.
    static let appStoreID: String = Bundle.main.configurationValue(for: "APP_STORE_ID")

    /// Opens the App Store straight on the write-a-review sheet.
    static let reviewURL: URL = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    /// Destination for in-app feedback.
    static let supportEmail: String = Bundle.main.configurationValue(for: "SUPPORT_EMAIL")

    static let privacyPolicyURL: URL = Bundle.main.configurationURL(for: "PRIVACY_POLICY_URL")

    static let tmdbURL: URL = Bundle.main.configurationURL(for: "TMDB_URL")
}
