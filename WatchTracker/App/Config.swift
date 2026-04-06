import Foundation

// MARK: - App Configuration
// Replace placeholder values with your actual credentials before running.

enum Config {
    /// Your Supabase project URL
    static let supabaseURL: URL = URL(string: "https://dextqapadrofqyizfgkp.supabase.co")!

    /// Your Supabase anonymous/public key
    static let supabasePublishableKey: String = "sb_publishable_zgE0HvRNp9a6BXdJ5Myh4A_fofdqlEy"

    /// Your backend API base URL
    static let apiBaseURL: URL = URL(string: "http://localhost:3000/api")!
}
