import Foundation
import Auth
@testable import WatchTracker

/// Stand-in for the Supabase auth SDK. Lock-guarded because `SupabaseAuthClient`
/// is `Sendable` and `AuthService` calls it from a `MainActor` context.
final class MockSupabaseAuthClient: SupabaseAuthClient, @unchecked Sendable {
    private let lock = NSLock()

    // MARK: - Configurable results

    private var _currentSessionResult: Result<Session, Error> = .success(AuthFixtures.session())
    private var _signUpResult: Result<(user: User, session: Session?), Error> = .success(
        (user: AuthFixtures.user(), session: AuthFixtures.session())
    )
    private var _signInResult: Result<Session, Error> = .success(AuthFixtures.session())
    private var _signOutError: Error?
    private var _resetPasswordError: Error?
    private var _verifyRecoveryOTPError: Error?
    private var _updatePasswordError: Error?

    var currentSessionResult: Result<Session, Error> {
        get { lock.withLock { _currentSessionResult } }
        set { lock.withLock { _currentSessionResult = newValue } }
    }
    var signUpResult: Result<(user: User, session: Session?), Error> {
        get { lock.withLock { _signUpResult } }
        set { lock.withLock { _signUpResult = newValue } }
    }
    var signInResult: Result<Session, Error> {
        get { lock.withLock { _signInResult } }
        set { lock.withLock { _signInResult = newValue } }
    }
    var signOutError: Error? {
        get { lock.withLock { _signOutError } }
        set { lock.withLock { _signOutError = newValue } }
    }
    var resetPasswordError: Error? {
        get { lock.withLock { _resetPasswordError } }
        set { lock.withLock { _resetPasswordError = newValue } }
    }
    var verifyRecoveryOTPError: Error? {
        get { lock.withLock { _verifyRecoveryOTPError } }
        set { lock.withLock { _verifyRecoveryOTPError = newValue } }
    }
    var updatePasswordError: Error? {
        get { lock.withLock { _updatePasswordError } }
        set { lock.withLock { _updatePasswordError = newValue } }
    }

    // MARK: - Call tracking

    private var _signOutCallCount = 0
    private var _resetPasswordCalls: [String] = []
    private var _verifyRecoveryOTPCalls: [(email: String, token: String)] = []
    private var _updatePasswordCalls: [String] = []

    var signOutCallCount: Int { lock.withLock { _signOutCallCount } }
    var resetPasswordCalls: [String] { lock.withLock { _resetPasswordCalls } }
    var verifyRecoveryOTPCalls: [(email: String, token: String)] { lock.withLock { _verifyRecoveryOTPCalls } }
    var updatePasswordCalls: [String] { lock.withLock { _updatePasswordCalls } }

    // MARK: - Auth state stream

    /// `AuthService` starts consuming this in `init`; tests that don't care simply
    /// never yield. Hold `continuation` to drive `.signedIn` / `.signedOut` by hand.
    let continuation: AsyncStream<(event: AuthChangeEvent, session: Session?)>.Continuation
    private let stream: AsyncStream<(event: AuthChangeEvent, session: Session?)>

    init() {
        var capturedContinuation: AsyncStream<(event: AuthChangeEvent, session: Session?)>.Continuation!
        stream = AsyncStream { capturedContinuation = $0 }
        continuation = capturedContinuation
    }

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> { stream }

    // MARK: - Protocol conformance

    func currentSession() async throws -> Session {
        try currentSessionResult.get()
    }

    func signUp(email: String, password: String, name: String) async throws -> (user: User, session: Session?) {
        try signUpResult.get()
    }

    func signIn(email: String, password: String) async throws -> Session {
        try signInResult.get()
    }

    func signOut() async throws {
        lock.withLock { _signOutCallCount += 1 }
        if let signOutError { throw signOutError }
    }

    func resetPasswordForEmail(_ email: String) async throws {
        lock.withLock { _resetPasswordCalls.append(email) }
        if let resetPasswordError { throw resetPasswordError }
    }

    func verifyRecoveryOTP(email: String, token: String) async throws {
        lock.withLock { _verifyRecoveryOTPCalls.append((email: email, token: token)) }
        if let verifyRecoveryOTPError { throw verifyRecoveryOTPError }
    }

    func updatePassword(_ newPassword: String) async throws {
        lock.withLock { _updatePasswordCalls.append(newPassword) }
        if let updatePasswordError { throw updatePasswordError }
    }
}

// MARK: - Supabase model fixtures

/// Supabase's `User` / `Session` have no test helpers of their own, so build the
/// minimum viable values here rather than repeating memberwise inits in every suite.
enum AuthFixtures {
    static func user(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
        email: String = "user@example.com",
        name: String = "Test User"
    ) -> User {
        User(
            id: id,
            appMetadata: [:],
            userMetadata: ["name": .string(name)],
            aud: "authenticated",
            email: email,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            isAnonymous: false
        )
    }

    static func session(user: User = user()) -> Session {
        Session(
            accessToken: "access-token",
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: Date().addingTimeInterval(3600).timeIntervalSince1970,
            refreshToken: "refresh-token",
            user: user
        )
    }
}
