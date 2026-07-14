import Foundation
import Combine
import Supabase
import Auth

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let client: SupabaseClient

    @MainActor private var isRecovering = false

    var session: Session? {
        get async {
            try? await client.auth.session
        }
    }

    init() {
        self.client = SupabaseManager.shared.client
        listenToAuthChanges()
    }

    // MARK: - Auth Methods

    func checkSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentUser = session.user
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }

    func signUp(email: String, password: String, name: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    /// Completes recovery: verifies the emailed code, then sets the new password.
    ///
    /// `verifyOTP` opens a session as a side effect, so the whole flow runs under
    /// `isRecovering` to keep the app on the auth screen. The session is always
    /// closed afterwards — on failure so a half-done reset never stays signed in,
    /// and on success so the user re-authenticates with their new password.
    @MainActor
    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws {
        isRecovering = true
        defer { isRecovering = false }

        try await client.auth.verifyOTP(email: email, token: code, type: .recovery)
        do {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            try? await client.auth.signOut()
            throw error
        }
        try? await client.auth.signOut()
    }

    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        await MainActor.run {
            self.currentUser = session.user
            self.isAuthenticated = true
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.resetLocalUserState()
        }
    }

    /// Permanently deletes the user's account and all their data. The backend removes
    /// the Supabase auth user and every DB row; the local session is then cleared.
    func deleteAccount() async throws {
        try await APIClient.shared.delete(.deleteAccount)
        try await client.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.resetLocalUserState()
        }
    }

    // MARK: - Private

    /// Clears all per-user local state so the next account starts clean.
    /// Called on sign-out and account deletion — the two paths that end a session.
    @MainActor
    private func resetLocalUserState() {
        // Navigation returns to the Home tab (logout is triggered from Profile).
        AppRouter.shared.selectedTab = .home
        AppRouter.shared.pendingShowId = nil

        // Previous account's cached watchlist.
        WatchlistStore.shared.cachedItems = []
        WatchlistStore.shared.needsRefresh = true

        // URL-keyed GET responses could otherwise serve another account's data.
        URLCache.shared.removeAllCachedResponses()

        // Per-user preferences / history persisted in UserDefaults.
        SearchHistoryManager().clearAll()
        UserDefaults.standard.removeObject(forKey: "discover.lastProviderId")
    }

    private func listenToAuthChanges() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
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
}

