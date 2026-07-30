import Foundation
import MessageUI
import Auth

@Observable
@MainActor
final class ProfileViewModel {

    // MARK: - Stats

    private(set) var stats: ProfileStats?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Preferences

    private(set) var episodeRemindersEnabled: Bool

    // MARK: - Feedback

    var isShowingMailComposer = false
    var isShowingMailUnavailable = false

    // MARK: - Account

    var isShowingDeleteConfirm = false
    private(set) var isDeleting = false
    private(set) var deleteError: String?

    /// Drives the delete-failure alert. Setting it to `false` is how the alert's dismiss
    /// button clears the message, so the view never has to hand-roll a `Binding`.
    var isShowingDeleteError: Bool {
        get { deleteError != nil }
        set { if !newValue { deleteError = nil } }
    }

    private let service: ProfileServiceProtocol
    private let auth: any AuthServiceProtocol
    private let notifications: NotificationScheduling
    private let defaults: UserDefaults
    private let canSendMail: @MainActor () -> Bool

    init(
        service: ProfileServiceProtocol = ProfileService(),
        auth: any AuthServiceProtocol,
        notifications: NotificationScheduling = NotificationService.shared,
        defaults: UserDefaults = .standard,
        canSendMail: @escaping @MainActor () -> Bool = { MFMailComposeViewController.canSendMail() }
    ) {
        self.service = service
        self.auth = auth
        self.notifications = notifications
        self.defaults = defaults
        self.canSendMail = canSendMail
        self.episodeRemindersEnabled = defaults.bool(forKey: NotificationService.episodeRemindersEnabledKey)
    }

    var currentUser: User? { auth.currentUser }

    // MARK: - Stats

    func fetchStats() async {
        if stats == nil { isLoading = true }
        errorMessage = nil

        do {
            stats = try await service.fetchStats()
        } catch {
            errorMessage = error.userFacingMessage
        }

        isLoading = false
    }

    // MARK: - Preferences

    /// Persists the reminder preference immediately so the toggle never lags, then reconciles
    /// with the system: enabling asks for permission and reverts on denial, disabling tears
    /// down whatever was already scheduled.
    func setEpisodeReminders(_ enabled: Bool) async {
        persistEpisodeReminders(enabled)

        if enabled {
            let granted = await notifications.requestAuthorization()
            if !granted { persistEpisodeReminders(false) }
        } else {
            await notifications.cancelAllEpisodeNotifications()
        }
    }

    private func persistEpisodeReminders(_ enabled: Bool) {
        episodeRemindersEnabled = enabled
        defaults.set(enabled, forKey: NotificationService.episodeRemindersEnabledKey)
    }

    // MARK: - Feedback

    var feedbackBody: String {
        FeedbackComposer.body(accountEmail: currentUser?.email)
    }

    /// Picks how to collect feedback. Returns a `mailto:` URL the caller must open — the only
    /// step that needs the view's `openURL` environment. A `nil` return means this view model
    /// already put the right sheet or alert on screen.
    func requestFeedback() -> URL? {
        if canSendMail() {
            isShowingMailComposer = true
            return nil
        }

        guard let url = FeedbackComposer.mailtoURL(accountEmail: currentUser?.email) else {
            isShowingMailUnavailable = true
            return nil
        }

        return url
    }

    /// Called when the system refuses to open the `mailto:` URL.
    func mailtoDidFail() {
        isShowingMailUnavailable = true
    }

    // MARK: - Account

    func signOut() async {
        try? await auth.signOut()
    }

    func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await auth.deleteAccount()
        } catch {
            deleteError = error.userFacingMessage
        }
    }
}
