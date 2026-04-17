import SwiftUI
import Supabase
import Security

@main
struct WatchTrackerApp: App {
    @State private var isAuthenticated = false
    @StateObject private var authService: AuthService

    init() {
        Self.clearKeychainIfFirstLaunch()
        _authService = StateObject(wrappedValue: AuthService())
    }

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

    private static func clearKeychainIfFirstLaunch() {
        let defaults = UserDefaults.standard
        let key = "hasLaunchedBefore"
        guard !defaults.bool(forKey: key) else { return }

        let classes: [CFString] = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        for secClass in classes {
            SecItemDelete([
                kSecClass: secClass,
                kSecAttrSynchronizable: kSecAttrSynchronizableAny
            ] as NSDictionary)
        }
        defaults.set(true, forKey: key)
    }
}
