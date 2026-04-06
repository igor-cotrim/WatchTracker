import Foundation
import Supabase

/// Shared Supabase client singleton used across the app.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabasePublishableKey
        )
    }
}
