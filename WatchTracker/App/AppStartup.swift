import Foundation

/// Work that runs once the authenticated UI appears: asking for notification permission on
/// the very first launch, then refreshing the scheduled episode reminders.
///
/// Lives here rather than in `WatchTrackerApp` because it must only run for a signed-in user —
/// `AppTabView`, its only caller, is exactly the view that appears when that becomes true.
@MainActor
struct AppStartup {
    private let service: WatchlistServiceProtocol
    private let notifications: NotificationScheduling
    private let defaults: UserDefaults

    init(
        service: WatchlistServiceProtocol,
        notifications: NotificationScheduling,
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.notifications = notifications
        self.defaults = defaults
    }

    func run() async {
        await requestNotificationPermissionOnFirstLaunch()
        await scheduleEpisodeReminders()
    }

    /// iOS only shows the system prompt once per install, so the flag keeps us from re-asking —
    /// and from re-enabling reminders the user has since turned off in Profile.
    private func requestNotificationPermissionOnFirstLaunch() async {
        guard !defaults.bool(forKey: NotificationService.hasRequestedAuthorizationKey) else { return }

        let granted = await notifications.requestAuthorization()
        defaults.set(true, forKey: NotificationService.hasRequestedAuthorizationKey)
        if granted {
            defaults.set(true, forKey: NotificationService.episodeRemindersEnabledKey)
        }
    }

    private func scheduleEpisodeReminders() async {
        guard let items = try? await service.fetchUpcoming() else { return }
        await notifications.scheduleNotifications(for: items)
    }
}
