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
}
