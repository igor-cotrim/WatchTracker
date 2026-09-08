import SwiftUI
import Supabase
import Security
import UserNotifications

@main
struct WatchTrackerApp: App {
    @State private var showSplash = true
    @State private var container: AppContainer
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system

    /// Held for the lifetime of the app because `UNUserNotificationCenter` keeps its
    /// delegate weakly.
    private let notificationDelegate: NotificationDelegate

    init() {
        Self.clearKeychainIfFirstLaunch()

        // The one place the object graph is built. Everything below — and every screen —
        // gets its dependencies from this instance rather than reaching for a singleton.
        let container = AppContainer.live
        _container = State(initialValue: container)

        notificationDelegate = NotificationDelegate(router: container.router)
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if container.auth.isAuthenticated {
                    AppTabView()
                } else {
                    AuthView(auth: container.auth)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.4), value: showSplash)
            .preferredColorScheme(appearance.colorScheme)
            .environment(container)
            .environment(container.router)
            .task {
                async let session: () = container.auth.checkSession()
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
