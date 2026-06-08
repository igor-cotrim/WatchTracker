import SwiftUI
import Supabase
import Security
import UserNotifications

@main
struct WatchTrackerApp: App {
    @State private var showSplash = true
    @StateObject private var authService: AuthService

    // Delegate stored as a static property so it is retained for the entire app lifetime
    // and can be assigned before the first scene render.
    private static let notificationDelegate = NotificationDelegate()

    init() {
        Self.clearKeychainIfFirstLaunch()
        _authService = StateObject(wrappedValue: AuthService())
        UNUserNotificationCenter.current().delegate = Self.notificationDelegate
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
            .environment(AppRouter.shared)
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

// MARK: - Notification Delegate

private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Show notification banner even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle tap — switch to Watching tab and push show detail
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let tmdbId = userInfo["tmdbId"] as? Int {
            DispatchQueue.main.async {
                AppRouter.shared.selectedTab = .watching
                AppRouter.shared.pendingShowId = tmdbId
            }
        }
        completionHandler()
    }
}
