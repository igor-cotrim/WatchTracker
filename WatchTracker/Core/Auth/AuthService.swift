import Foundation
import Supabase
import Auth

/// Sign-up outcomes that are not failures of the request itself.
enum AuthServiceError: LocalizedError {
    /// Supabase accepted the sign-up but withheld a session pending email confirmation.
    case emailConfirmationRequired

    var errorDescription: String? {
        switch self {
        case .emailConfirmationRequired: Strings.Auth.emailConfirmationRequired
        }
    }
}

// MARK: - Protocols

/// What the auth screens need from `AuthService`. Views and view models depend on this
/// rather than the concrete service, so they can be driven by a stub in tests.
@MainActor
protocol AuthServiceProtocol: AnyObject {
    var sessionExpiredMessage: String? { get }
    func clearSessionExpiredMessage()
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, name: String) async throws
    func resetPassword(email: String) async throws
    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws
}

/// The slice of Supabase's `AuthClient` that `AuthService` actually uses.
///
/// Deliberately narrow: it exists so the sign-in/out state machine can be exercised
/// without a live Supabase client, not to mirror the SDK.
protocol SupabaseAuthClient: Sendable {
    func currentSession() async throws -> Session
    func signUp(email: String, password: String, name: String) async throws -> (user: User, session: Session?)
    func signIn(email: String, password: String) async throws -> Session
    func signOut() async throws
    func resetPasswordForEmail(_ email: String) async throws
    func verifyRecoveryOTP(email: String, token: String) async throws
    func updatePassword(_ newPassword: String) async throws
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> { get }
}

/// Production `SupabaseAuthClient`, and the only place the Supabase SDK is called.
struct LiveSupabaseAuthClient: SupabaseAuthClient {
    private let client: SupabaseClient

    init(_ client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    func currentSession() async throws -> Session {
        try await client.auth.session
    }

    func signUp(email: String, password: String, name: String) async throws -> (user: User, session: Session?) {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )
        return (response.user, response.session)
    }

    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPasswordForEmail(_ email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func verifyRecoveryOTP(email: String, token: String) async throws {
        try await client.auth.verifyOTP(email: email, token: token, type: .recovery)
    }

    func updatePassword(_ newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        client.auth.authStateChanges
    }
}

// MARK: - AuthService

@Observable
@MainActor
final class AuthService: AuthServiceProtocol {
    private(set) var isAuthenticated = false
    private(set) var currentUser: User?

    /// Set when the session is lost mid-use (a 401) so `AuthView` can explain why
    /// the user was returned to the login screen. Cleared on the next sign-in attempt.
    private(set) var sessionExpiredMessage: String?

    private let client: any SupabaseAuthClient
    private let api: APIClient
    private let router: AppRouter
    private let store: WatchlistStore
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter

    private var isRecovering = false
    private var isHandlingUnauthorized = false

    /// Kept so the observer can be torn down; otherwise a discarded service keeps
    /// reacting to every 401 in the process.
    @ObservationIgnored
    nonisolated(unsafe) private var unauthorizedObserver: (any NSObjectProtocol)?

    var session: Session? {
        get async {
            try? await client.currentSession()
        }
    }

    init(
        client: any SupabaseAuthClient = LiveSupabaseAuthClient(),
        api: APIClient = .shared,
        router: AppRouter = .shared,
        store: WatchlistStore = .shared,
        userDefaults: UserDefaults = .standard,
        // Injectable so parallel tests don't sign each other out: `.authUnauthorized`
        // is a process-wide broadcast, and every live service reacts to it.
        notificationCenter: NotificationCenter = .default
    ) {
        self.client = client
        self.api = api
        self.router = router
        self.store = store
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        listenToAuthChanges()
        listenToUnauthorized()
    }

    deinit {
        if let unauthorizedObserver {
            notificationCenter.removeObserver(unauthorizedObserver)
        }
    }

    // MARK: - Auth Methods

    func clearSessionExpiredMessage() {
        sessionExpiredMessage = nil
    }

    func checkSession() async {
        do {
            let session = try await client.currentSession()
            currentUser = session.user
            isAuthenticated = true
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    func signUp(email: String, password: String, name: String) async throws {
        let response = try await client.signUp(email: email, password: password, name: name)

        // With email confirmation enabled, Supabase returns a user but no session.
        // Signing in here would leave every request unauthenticated — `APIClient` simply
        // omits the header when there is no token — so surface it instead.
        guard response.session != nil else {
            throw AuthServiceError.emailConfirmationRequired
        }

        currentUser = response.user
        isAuthenticated = true
        sessionExpiredMessage = nil
    }

    func resetPassword(email: String) async throws {
        try await client.resetPasswordForEmail(email)
    }

    /// Completes recovery: verifies the emailed code, then sets the new password.
    ///
    /// `verifyOTP` opens a session as a side effect, so the whole flow runs under
    /// `isRecovering` to keep the app on the auth screen. The session is always
    /// closed afterwards — on failure so a half-done reset never stays signed in,
    /// and on success so the user re-authenticates with their new password.
    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws {
        isRecovering = true
        defer { isRecovering = false }

        try await client.verifyRecoveryOTP(email: email, token: code)
        do {
            try await client.updatePassword(newPassword)
        } catch {
            try? await client.signOut()
            throw error
        }
        try? await client.signOut()
    }

    func signIn(email: String, password: String) async throws {
        let session = try await client.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
        sessionExpiredMessage = nil
    }

    func signOut() async throws {
        try await client.signOut()
        currentUser = nil
        isAuthenticated = false
        resetLocalUserState()
    }

    /// Permanently deletes the user's account and all their data. The backend removes
    /// the Supabase auth user and every DB row; the local session is then cleared.
    func deleteAccount() async throws {
        try await api.delete(.deleteAccount)
        try await client.signOut()
        currentUser = nil
        isAuthenticated = false
        resetLocalUserState()
    }

    // MARK: - Internal

    /// Signs out on session loss. Guarded so parallel 401s trigger a single logout,
    /// and skipped during password recovery (which opens/closes sessions on purpose).
    func handleUnauthorized() async {
        guard isAuthenticated, !isRecovering, !isHandlingUnauthorized else { return }
        isHandlingUnauthorized = true
        defer { isHandlingUnauthorized = false }

        sessionExpiredMessage = Strings.Auth.sessionExpired
        try? await signOut()
    }

    // MARK: - Private

    /// Clears all per-user local state so the next account starts clean.
    /// Called on sign-out and account deletion — the two paths that end a session.
    private func resetLocalUserState() {
        // Navigation returns to the Home tab (logout is triggered from Profile).
        router.selectedTab = .home
        router.pendingShowId = nil

        // Previous account's cached watchlist.
        store.cachedItems = []
        store.needsRefresh = true

        // URL-keyed GET responses could otherwise serve another account's data.
        URLCache.shared.removeAllCachedResponses()

        // Per-user preferences / history persisted in UserDefaults.
        SearchHistoryManager(userDefaults: userDefaults).clearAll()
        userDefaults.removeObject(forKey: "discover.lastProviderId")
    }

    /// Observes 401s surfaced by `APIClient` and forces a sign-out so the user is
    /// returned to `AuthView` instead of staying on a silently-failing authed UI.
    private func listenToUnauthorized() {
        unauthorizedObserver = notificationCenter.addObserver(
            forName: .authUnauthorized,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleUnauthorized()
            }
        }
    }

    private func listenToAuthChanges() {
        Task { [weak self, client] in
            for await (event, session) in client.authStateChanges {
                guard let self else { return }
                switch event {
                case .signedIn:
                    if self.isRecovering { break }
                    self.currentUser = session?.user
                    self.isAuthenticated = true
                case .signedOut:
                    self.currentUser = nil
                    self.isAuthenticated = false
                default:
                    break
                }
            }
        }
    }
}
