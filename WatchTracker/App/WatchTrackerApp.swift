import SwiftUI
import Supabase
import Security

@main
struct WatchTrackerApp: App {
    @State private var showSplash = true
    @StateObject private var authService: AuthService

    init() {
        Self.clearKeychainIfFirstLaunch()
        _authService = StateObject(wrappedValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authService.isAuthenticated {
                    AppTabView()
                } else {
                    AuthView()
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.4), value: showSplash)
            .environmentObject(authService)
            .task {
                async let session: () = authService.checkSession()
                async let minDelay: () = { try? await Task.sleep(for: .seconds(1.2)) }()
                _ = await (session, minDelay)
                showSplash = false
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
