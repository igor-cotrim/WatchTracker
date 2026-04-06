import SwiftUI
import Supabase

@main
struct WatchTrackerApp: App {
    @State private var isAuthenticated = false
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    AppTabView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(authService)
            .task {
                await authService.checkSession()
            }
        }
    }
}
