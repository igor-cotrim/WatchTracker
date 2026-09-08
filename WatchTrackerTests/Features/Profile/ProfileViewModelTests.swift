import Foundation
import Testing
import Auth
@testable import WatchTracker

@Suite("ProfileViewModel", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
@MainActor
struct ProfileViewModelTests {

    private func makeViewModel() -> (ProfileViewModel, MockProfileService) {
        let service = MockProfileService()
        return (ProfileViewModel(service: service, auth: MockAuthService(), notifications: MockNotificationScheduler()), service)
    }

    @Test func `fetchStats publishes the stats`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .success(TestFixtures.profileStats(episodesWatched: 99))

        await vm.fetchStats()

        #expect(vm.stats?.episodesWatched == 99)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
        #expect(service.fetchStatsCallCount == 1)
    }

    @Test func `failure sets a user-facing message and leaves stats nil`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .failure(MockError.generic("boom"))

        await vm.fetchStats()

        #expect(vm.stats == nil)
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }

    @Test func `a connection failure uses the friendly connection copy`() async {
        // ProfileViewModel is the one ViewModel using `userFacingMessage` instead of
        // `localizedDescription`, so a dropped connection must not leak URLError text.
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .failure(URLError(.notConnectedToInternet))

        await vm.fetchStats()

        #expect(vm.errorMessage == Strings.Common.connectionError)
    }

    @Test func `a refresh keeps the previous stats visible on failure`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .success(TestFixtures.profileStats(episodesWatched: 42))
        await vm.fetchStats()

        service.fetchStatsResult = .failure(MockError.generic("boom"))
        await vm.fetchStats()

        #expect(vm.stats?.episodesWatched == 42, "Stale data beats an empty screen")
        #expect(vm.errorMessage != nil)
    }

    @Test func `a successful refresh clears the previous error`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .failure(MockError.generic("boom"))
        await vm.fetchStats()
        #expect(vm.errorMessage != nil)

        service.fetchStatsResult = .success(TestFixtures.profileStats())
        await vm.fetchStats()
        #expect(vm.errorMessage == nil)
    }

    @Test func `isLoading is false once the fetch settles`() async {
        let (vm, _) = makeViewModel()
        await vm.fetchStats()
        #expect(vm.isLoading == false)
    }

    @Test func `refetching does not re-enter the loading state`() async {
        // `isLoading` only guards the first load; refreshes keep the UI populated.
        let (vm, _) = makeViewModel()
        await vm.fetchStats()
        await vm.fetchStats()
        #expect(vm.isLoading == false)
        #expect(vm.stats != nil)
    }

    @Test func `currentUser comes straight from the auth service`() {
        let auth = MockAuthService(currentUser: AuthFixtures.user(email: "her@example.com"))
        let vm = ProfileViewModel(service: MockProfileService(), auth: auth, notifications: MockNotificationScheduler())

        #expect(vm.currentUser?.email == "her@example.com")
    }

    // MARK: - Episode reminders

    @Suite("Episode reminders", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
    @MainActor
    struct EpisodeRemindersTests {

        private final class Harness {
            let notifications = MockNotificationScheduler()
            let defaults: UserDefaults
            private let suiteName: String

            init(remindersEnabled: Bool = false) {
                suiteName = "test-\(UUID().uuidString)"
                defaults = UserDefaults(suiteName: suiteName)!
                defaults.set(remindersEnabled, forKey: NotificationService.episodeRemindersEnabledKey)
            }

            func makeViewModel() -> ProfileViewModel {
                ProfileViewModel(
                    service: MockProfileService(),
                    auth: MockAuthService(),
                    notifications: notifications,
                    defaults: defaults
                )
            }

            var persisted: Bool {
                defaults.bool(forKey: NotificationService.episodeRemindersEnabledKey)
            }

            deinit { defaults.removePersistentDomain(forName: suiteName) }
        }

        @Test func `the initial value is read from the persisted preference`() {
            let harness = Harness(remindersEnabled: true)
            #expect(harness.makeViewModel().episodeRemindersEnabled)
        }

        @Test func `enabling with permission granted persists the preference`() async {
            let harness = Harness()
            harness.notifications.authorizationResult = true
            let vm = harness.makeViewModel()

            await vm.setEpisodeReminders(true)

            #expect(vm.episodeRemindersEnabled)
            #expect(harness.persisted)
            #expect(harness.notifications.authorizationRequestCount == 1)
        }

        @Test func `enabling with permission denied reverts without cancelling`() async {
            // Regression guard: the old View-level `.onChange` handler wrote the preference
            // back to false, which re-entered itself and fired a redundant cancel.
            let harness = Harness()
            harness.notifications.authorizationResult = false
            let vm = harness.makeViewModel()

            await vm.setEpisodeReminders(true)

            #expect(vm.episodeRemindersEnabled == false)
            #expect(harness.persisted == false)
            #expect(harness.notifications.cancelCount == 0)
        }

        @Test func `disabling persists the preference and cancels exactly once`() async {
            let harness = Harness(remindersEnabled: true)
            let vm = harness.makeViewModel()

            await vm.setEpisodeReminders(false)

            #expect(vm.episodeRemindersEnabled == false)
            #expect(harness.persisted == false)
            #expect(harness.notifications.cancelCount == 1)
            #expect(harness.notifications.authorizationRequestCount == 0)
        }
    }

    // MARK: - Feedback

    @Suite("Feedback", .tags(.viewModel), .timeLimit(.minutes(1)))
    @MainActor
    struct FeedbackTests {

        private func makeViewModel(canSendMail: Bool) -> ProfileViewModel {
            ProfileViewModel(
                service: MockProfileService(),
                auth: MockAuthService(currentUser: AuthFixtures.user()),
                notifications: MockNotificationScheduler(),
                canSendMail: { canSendMail }
            )
        }

        @Test func `a mail-capable device opens the in-app composer`() {
            let vm = makeViewModel(canSendMail: true)

            let url = vm.requestFeedback()

            #expect(url == nil, "Nothing for the view to open — the sheet handles it")
            #expect(vm.isShowingMailComposer)
            #expect(vm.isShowingMailUnavailable == false)
        }

        @Test func `without a mail account it hands back a mailto URL`() {
            let vm = makeViewModel(canSendMail: false)

            let url = vm.requestFeedback()

            #expect(url?.scheme == "mailto")
            #expect(vm.isShowingMailComposer == false)
            #expect(vm.isShowingMailUnavailable == false)
        }

        @Test func `a refused mailto URL surfaces the unavailable alert`() {
            let vm = makeViewModel(canSendMail: false)
            _ = vm.requestFeedback()

            vm.mailtoDidFail()

            #expect(vm.isShowingMailUnavailable)
        }

        @Test func `the body carries the signed-in account email`() {
            let vm = makeViewModel(canSendMail: true)
            #expect(vm.feedbackBody.contains("user@example.com"))
        }
    }

    // MARK: - Account

    @Suite("Account", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
    @MainActor
    struct AccountTests {

        private func makeViewModel(auth: MockAuthService) -> ProfileViewModel {
            ProfileViewModel(service: MockProfileService(), auth: auth, notifications: MockNotificationScheduler())
        }

        @Test func `signOut delegates to the auth service`() async {
            let auth = MockAuthService()
            let vm = makeViewModel(auth: auth)

            await vm.signOut()

            #expect(auth.signOutCallCount == 1)
        }

        @Test func `a failed signOut is swallowed`() async {
            // Sign-out failures leave the session intact; there is no UI for them today.
            let auth = MockAuthService()
            auth.signOutError = MockError.generic("boom")
            let vm = makeViewModel(auth: auth)

            await vm.signOut()

            #expect(auth.signOutCallCount == 1)
        }

        @Test func `deleteAccount succeeds without an error`() async {
            let auth = MockAuthService()
            let vm = makeViewModel(auth: auth)

            await vm.deleteAccount()

            #expect(auth.deleteAccountCallCount == 1)
            #expect(vm.deleteError == nil)
            #expect(vm.isShowingDeleteError == false)
            #expect(vm.isDeleting == false)
        }

        @Test func `a failed delete surfaces a user-facing message`() async {
            let auth = MockAuthService()
            auth.deleteAccountError = URLError(.notConnectedToInternet)
            let vm = makeViewModel(auth: auth)

            await vm.deleteAccount()

            #expect(vm.deleteError == Strings.Common.connectionError)
            #expect(vm.isShowingDeleteError)
            #expect(vm.isDeleting == false, "The spinner must stop even when the call throws")
        }

        @Test func `dismissing the error alert clears the message`() async {
            let auth = MockAuthService()
            auth.deleteAccountError = MockError.generic("boom")
            let vm = makeViewModel(auth: auth)
            await vm.deleteAccount()

            vm.isShowingDeleteError = false

            #expect(vm.deleteError == nil)
        }

        @Test func `isDeleting is true while the call is in flight`() async {
            let auth = MockAuthService()
            let vm = makeViewModel(auth: auth)
            var deletingDuringCall: Bool?
            auth.onCall = { deletingDuringCall = vm.isDeleting }

            await vm.deleteAccount()

            #expect(deletingDuringCall == true)
            #expect(vm.isDeleting == false)
        }
    }
}
