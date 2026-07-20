import Foundation

// MARK: - App Configuration
// Replace placeholder values with your actual credentials before running.

enum Config {
    /// Supabase project URL — safe for client distribution.
    static let supabaseURL: URL = URL(string: "https://dextqapadrofqyizfgkp.supabase.co")!

    /// Publishable (anon) key only. RLS enforces authorization server-side.
    /// NEVER place the service_role / secret key here — it bypasses RLS.
    static let supabasePublishableKey: String = "sb_publishable_zgE0HvRNp9a6BXdJ5Myh4A_fofdqlEy"

    static let apiBaseURL: URL = URL(string: "https://watch-tracker-backend-916835188736.southamerica-east1.run.app/api")!

    // MARK: - Analytics (PostHog)

    /// PostHog project API key — safe for client distribution (write-only ingestion key).
    /// Replace with your real project key from PostHog → Project Settings.
    static let posthogAPIKey: String = "phc_rqcN9Enctc55wd8FAFRBzazgorgNApnn28gJtiyd3M9E"

    /// PostHog ingestion host. Use "https://eu.i.posthog.com" for EU-hosted projects.
    static let posthogHost: String = "https://us.i.posthog.com"
}
