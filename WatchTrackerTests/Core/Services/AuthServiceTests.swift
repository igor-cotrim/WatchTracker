import Foundation
import Testing
import Auth
@testable import WatchTracker

@MainActor
@Suite("AuthService", .tags(.service, .async), .timeLimit(.minutes(1)))
struct AuthServiceTests {

    /// Owns the injected collaborators so each test gets an isolated router, store
    /// and defaults suite instead of touching the app-wide singletons.
    private final class Harness {
        let client = MockSupabaseAuthClient()
        let analytics = MockAnalytics()
        let router: AppRouter
        let store = WatchlistStore()
        let defaults: UserDefaults
        let notifications = MockNotificationScheduler()
        /// Private so a 401 raised by a suite running in parallel can't sign this
        /// service out — `.authUnauthorized` is otherwise a process-wide broadcast.
        let notificationCenter = NotificationCenter()
        /// Stubbed so no test can reach the network; `deleteAccount` is the one path that calls out.
        let recorder: StubURLProtocol.Recorder
        let service: AuthService
        private let suiteName: String

        @MainActor
        init() {
            suiteName = "test-\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suiteName)!
            router = AppRouter(analytics: analytics)
            let (session, recorder) = StubURLProtocol.session(.json("{}"))
            self.recorder = recorder
            service = AuthService(
                client: client,
                api: APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock()),
                router: router,
                store: store,
                userDefaults: defaults,
                notifications: notifications,
                notificationCenter: notificationCenter
            )
        }

        deinit {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }

    // MARK: - checkSession

    @Test func `checkSession authenticates when a session exists`() async {
        let harness = Harness()

        await harness.service.checkSession()

        #expect(harness.service.isAuthenticated)
        #expect(harness.service.currentUser?.email == "user@example.com")
    }

    @Test func `checkSession clears state when no session exists`() async {
        let harness = Harness()
        harness.client.currentSessionResult = .failure(MockError.generic("no session"))

        await harness.service.checkSession()

        #expect(harness.service.isAuthenticated == false)
        #expect(harness.service.currentUser == nil)
    }

    // MARK: - signUp

    @Test func `signUp authenticates when Supabase returns a session`() async throws {
        let harness = Harness()

        try await harness.service.signUp(email: "a@b.com", password: "Password1", name: "Test")

        #expect(harness.service.isAuthenticated)
        #expect(harness.service.currentUser != nil)
    }

    /// With email confirmation on, Supabase returns a user but no session. Signing the
    /// user in anyway would leave every API request unauthenticated.
    @Test func `signUp without a session throws emailConfirmationRequired`() async {
        let harness = Harness()
        harness.client.signUpResult = .success((user: AuthFixtures.user(), session: nil))

        await #expect(throws: AuthServiceError.emailConfirmationRequired) {
            try await harness.service.signUp(email: "a@b.com", password: "Password1", name: "Test")
        }
    }

    @Test func `signUp without a session leaves the user unauthenticated`() async {
        let harness = Harness()
        harness.client.signUpResult = .success((user: AuthFixtures.user(), session: nil))

        try? await harness.service.signUp(email: "a@b.com", password: "Password1", name: "Test")

        #expect(harness.service.isAuthenticated == false)
        #expect(harness.service.currentUser == nil)
    }

    @Test func `signUp propagates a transport failure`() async {
        let harness = Harness()
        harness.client.signUpResult = .failure(APIError.serverError)

        await #expect(throws: APIError.serverError) {
            try await harness.service.signUp(email: "a@b.com", password: "Password1", name: "Test")
        }
    }

    // MARK: - signIn

    @Test func `signIn authenticates and clears the session-expired message`() async throws {
        let harness = Harness()
        await harness.service.handleUnauthorizedForTesting()

        try await harness.service.signIn(email: "a@b.com", password: "secret")

        #expect(harness.service.isAuthenticated)
        #expect(harness.service.sessionExpiredMessage == nil)
    }

    @Test func `signIn propagates a failure without authenticating`() async {
        let harness = Harness()
        harness.client.signInResult = .failure(APIError.unauthorized)

        await #expect(throws: APIError.unauthorized) {
            try await harness.service.signIn(email: "a@b.com", password: "wrong")
        }
        #expect(harness.service.isAuthenticated == false)
    }

    // MARK: - signOut and local state

    @Test func `signOut clears the authenticated state`() async throws {
        let harness = Harness()
        try await harness.service.signIn(email: "a@b.com", password: "secret")

        try await harness.service.signOut()

        #expect(harness.service.isAuthenticated == false)
        #expect(harness.service.currentUser == nil)
        #expect(harness.client.signOutCallCount == 1)
    }

    @Test func `signOut resets navigation, the watchlist cache and stored preferences`() async throws {
        let harness = Harness()
        harness.router.selectedTab = .profile
        harness.router.pendingShowId = 1399
        harness.store.cachedItems = [TestFixtures.watchItem()]
        harness.store.needsRefresh = false
        harness.defaults.set(8, forKey: "discover.lastProviderId")
        SearchHistoryManager(userDefaults: harness.defaults).save(query: "dune")

        try await harness.service.signOut()

        #expect(harness.router.selectedTab == .home)
        #expect(harness.router.pendingShowId == nil)
        #expect(harness.store.cachedItems.isEmpty)
        #expect(harness.store.needsRefresh)
        #expect(harness.defaults.object(forKey: "discover.lastProviderId") == nil)
        #expect(SearchHistoryManager(userDefaults: harness.defaults).load().isEmpty)
    }

    @Test func `a failing signOut leaves local state untouched`() async {
        let harness = Harness()
        harness.client.signOutError = APIError.serverError
        harness.store.cachedItems = [TestFixtures.watchItem()]

        await #expect(throws: APIError.serverError) {
            try await harness.service.signOut()
        }
        #expect(harness.store.cachedItems.count == 1)
    }

    // MARK: - Notification teardown
    //
    // Episode reminders carry show and episode titles in their payload, so anything one
    // account queued must not survive into the next one's lock screen.

    @Test func `signOut wipes every queued notification`() async throws {
        let harness = Harness()

        try await harness.service.signOut()

        #expect(harness.notifications.removeAllCount == 1)
    }

    @Test func `signOut keeps the device-level notification preferences`() async throws {
        // Both describe the device, not the user: the reminder opt-in is a standing choice
        // nobody wants to redo after every login, and the prompt flag records that iOS has
        // already shown its one-time system alert. Emptying the queue above is what makes
        // keeping the opt-in safe — the next account only ever gets its own shows scheduled.
        let harness = Harness()
        harness.defaults.set(true, forKey: NotificationService.episodeRemindersEnabledKey)
        harness.defaults.set(true, forKey: NotificationService.hasRequestedAuthorizationKey)

        try await harness.service.signOut()

        #expect(harness.defaults.bool(forKey: NotificationService.episodeRemindersEnabledKey))
        #expect(harness.defaults.bool(forKey: NotificationService.hasRequestedAuthorizationKey))
    }

    @Test func `signOut clears the new-season dedupe flags`() async throws {
        // Left behind, these both reveal which shows the previous user tracked and
        // silence the new-season alert for whoever signs in next.
        let harness = Harness()
        harness.defaults.set(true, forKey: NotificationService.newSeasonDedupeKey(tmdbId: 1399, season: 4))
        harness.defaults.set(true, forKey: NotificationService.newSeasonDedupeKey(tmdbId: 66732, season: 5))

        try await harness.service.signOut()

        let leftover = harness.defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(NotificationService.newSeasonDedupePrefix) }
        #expect(leftover.isEmpty)
    }

    @Test func `deleteAccount wipes the queued notifications and the dedupe flags`() async throws {
        let harness = Harness()
        harness.defaults.set(true, forKey: NotificationService.newSeasonDedupeKey(tmdbId: 1399, season: 4))

        try await harness.service.deleteAccount()

        #expect(harness.notifications.removeAllCount == 1)
        #expect(harness.defaults.object(forKey: NotificationService.newSeasonDedupeKey(tmdbId: 1399, season: 4)) == nil)
    }

    @Test func `a failing signOut keeps the notifications queued`() async {
        // The session survives a failed sign-out, so its reminders must too.
        let harness = Harness()
        harness.client.signOutError = APIError.serverError
        harness.defaults.set(true, forKey: NotificationService.newSeasonDedupeKey(tmdbId: 1399, season: 4))

        await #expect(throws: APIError.serverError) {
            try await harness.service.signOut()
        }

        #expect(harness.notifications.removeAllCount == 0)
        #expect(harness.defaults.object(forKey: NotificationService.newSeasonDedupeKey(tmdbId: 1399, season: 4)) != nil)
    }

    // MARK: - confirmPasswordReset

    @Test func `confirmPasswordReset verifies the code then updates the password`() async throws {
        let harness = Harness()

        try await harness.service.confirmPasswordReset(
            email: "a@b.com", code: "123456", newPassword: "Password1"
        )

        #expect(harness.client.verifyRecoveryOTPCalls.count == 1)
        #expect(harness.client.verifyRecoveryOTPCalls.first?.token == "123456")
        #expect(harness.client.updatePasswordCalls == ["Password1"])
    }

    /// The recovery OTP opens a session as a side effect, so the flow must always
    /// close it — otherwise the user stays signed in on their old password.
    @Test func `confirmPasswordReset signs out after succeeding`() async throws {
        let harness = Harness()

        try await harness.service.confirmPasswordReset(
            email: "a@b.com", code: "123456", newPassword: "Password1"
        )

        #expect(harness.client.signOutCallCount == 1)
    }

    @Test func `confirmPasswordReset signs out and rethrows when the update fails`() async {
        let harness = Harness()
        harness.client.updatePasswordError = APIError.serverError

        await #expect(throws: APIError.serverError) {
            try await harness.service.confirmPasswordReset(
                email: "a@b.com", code: "123456", newPassword: "Password1"
            )
        }
        #expect(harness.client.signOutCallCount == 1)
    }

    @Test func `confirmPasswordReset does not sign out when the code is rejected`() async {
        let harness = Harness()
        harness.client.verifyRecoveryOTPError = APIError.unauthorized

        await #expect(throws: APIError.unauthorized) {
            try await harness.service.confirmPasswordReset(
                email: "a@b.com", code: "000000", newPassword: "Password1"
            )
        }
        #expect(harness.client.signOutCallCount == 0)
        #expect(harness.client.updatePasswordCalls.isEmpty)
    }

    // MARK: - handleUnauthorized

    @Test func `handleUnauthorized signs out and explains why`() async throws {
        let harness = Harness()
        try await harness.service.signIn(email: "a@b.com", password: "secret")

        await harness.service.handleUnauthorized()

        #expect(harness.service.isAuthenticated == false)
        #expect(harness.service.sessionExpiredMessage == Strings.Auth.sessionExpired)
    }

    @Test func `handleUnauthorized is a no-op when already signed out`() async {
        let harness = Harness()

        await harness.service.handleUnauthorized()

        #expect(harness.service.sessionExpiredMessage == nil)
        #expect(harness.client.signOutCallCount == 0)
    }

    /// End-to-end through the notification `APIClient` posts on a 401.
    @Test func `an authUnauthorized notification signs the user out`() async throws {
        let harness = Harness()
        try await harness.service.signIn(email: "a@b.com", password: "secret")

        harness.notificationCenter.post(name: .authUnauthorized, object: nil)

        // The observer hops through a Task, so let it drain.
        try await Task.sleep(for: .milliseconds(50))
        #expect(harness.service.isAuthenticated == false)
        #expect(harness.service.sessionExpiredMessage == Strings.Auth.sessionExpired)
    }

    @Test func `clearSessionExpiredMessage removes the explanation`() async throws {
        let harness = Harness()
        try await harness.service.signIn(email: "a@b.com", password: "secret")
        await harness.service.handleUnauthorized()
        #expect(harness.service.sessionExpiredMessage != nil)

        harness.service.clearSessionExpiredMessage()

        #expect(harness.service.sessionExpiredMessage == nil)
    }

    // MARK: - deleteAccount

    @Test func `deleteAccount calls the backend, signs out and clears local state`() async throws {
        let (session, recorder) = StubURLProtocol.session(.json("{}"))
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        let client = MockSupabaseAuthClient()
        let store = WatchlistStore()
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = AuthService(
            client: client, api: api, router: AppRouter(analytics: MockAnalytics()), store: store,
            userDefaults: defaults, notifications: MockNotificationScheduler(),
            notificationCenter: NotificationCenter()
        )
        try await service.signIn(email: "a@b.com", password: "secret")
        store.cachedItems = [TestFixtures.watchItem()]

        try await service.deleteAccount()

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path.hasSuffix(Endpoint.deleteAccount.path) == true)
        #expect(client.signOutCallCount == 1)
        #expect(service.isAuthenticated == false)
        #expect(store.cachedItems.isEmpty)
    }

    @Test func `deleteAccount does not sign out when the backend rejects it`() async throws {
        let (session, _) = StubURLProtocol.session(.json("{}", statusCode: 500))
        let api = APIClient(session: session, tokenProvider: { "token" }, clock: ImmediateClock())
        let client = MockSupabaseAuthClient()
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = AuthService(
            client: client, api: api, router: AppRouter(analytics: MockAnalytics()), store: WatchlistStore(),
            userDefaults: defaults, notifications: MockNotificationScheduler(),
            notificationCenter: NotificationCenter()
        )
        try await service.signIn(email: "a@b.com", password: "secret")

        await #expect(throws: APIError.serverError) {
            try await service.deleteAccount()
        }
        #expect(client.signOutCallCount == 0)
        #expect(service.isAuthenticated)
    }
}

// MARK: - Test helpers

private extension AuthService {
    /// Puts the service into the "session expired" state the way a 401 would,
    /// so sign-in can be observed clearing it.
    func handleUnauthorizedForTesting() async {
        try? await signIn(email: "seed@example.com", password: "seed")
        await handleUnauthorized()
    }
}
