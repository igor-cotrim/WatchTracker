import Foundation
import Auth
@testable import WatchTracker

@MainActor
final class MockAuthService: AuthServiceProtocol {

    // MARK: - Configurable results

    var isAuthenticated = false
    var currentUser: User?
    var signInError: Error?
    var signUpError: Error?
    var resetPasswordError: Error?
    var confirmPasswordResetError: Error?
    var signOutError: Error?
    var deleteAccountError: Error?

    private(set) var sessionExpiredMessage: String?

    // MARK: - Call tracking

    private(set) var signInCalls: [(email: String, password: String)] = []
    private(set) var signUpCalls: [(email: String, password: String, name: String)] = []
    private(set) var resetPasswordCalls: [String] = []
    private(set) var confirmPasswordResetCalls: [(email: String, code: String, newPassword: String)] = []
    private(set) var clearSessionExpiredMessageCallCount = 0
    private(set) var checkSessionCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var deleteAccountCallCount = 0

    /// Runs inside each async method before it returns, so tests can observe the
    /// view model's in-flight state (e.g. `isLoading`) or re-enter it deterministically.
    var onCall: (@MainActor () async -> Void)?

    init(sessionExpiredMessage: String? = nil, currentUser: User? = nil) {
        self.sessionExpiredMessage = sessionExpiredMessage
        self.currentUser = currentUser
    }

    // MARK: - Protocol conformance

    func clearSessionExpiredMessage() {
        clearSessionExpiredMessageCallCount += 1
        sessionExpiredMessage = nil
    }

    func checkSession() async {
        checkSessionCallCount += 1
        await onCall?()
    }

    func signIn(email: String, password: String) async throws {
        signInCalls.append((email: email, password: password))
        await onCall?()
        if let signInError { throw signInError }
    }

    func signUp(email: String, password: String, name: String) async throws {
        signUpCalls.append((email: email, password: password, name: name))
        await onCall?()
        if let signUpError { throw signUpError }
    }

    func resetPassword(email: String) async throws {
        resetPasswordCalls.append(email)
        await onCall?()
        if let resetPasswordError { throw resetPasswordError }
    }

    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws {
        confirmPasswordResetCalls.append((email: email, code: code, newPassword: newPassword))
        await onCall?()
        if let confirmPasswordResetError { throw confirmPasswordResetError }
    }

    func signOut() async throws {
        signOutCallCount += 1
        await onCall?()
        if let signOutError { throw signOutError }
    }

    func deleteAccount() async throws {
        deleteAccountCallCount += 1
        await onCall?()
        if let deleteAccountError { throw deleteAccountError }
    }
}
