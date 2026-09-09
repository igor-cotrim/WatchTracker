import Foundation
import Testing
@testable import WatchTracker

@MainActor
@Suite("AuthViewModel", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct AuthViewModelTests {

    private func makeViewModel(
        sessionExpiredMessage: String? = nil
    ) -> (AuthViewModel, MockAuthService) {
        let auth = MockAuthService(sessionExpiredMessage: sessionExpiredMessage)
        return (AuthViewModel(auth: auth), auth)
    }

    /// Fills the form with credentials that satisfy sign-up validation.
    private func fill(_ viewModel: AuthViewModel) {
        viewModel.name = "Test User"
        viewModel.email = "user@example.com"
        viewModel.password = "Password1"
    }

    // MARK: - Validation

    @Test func `starts in sign-in mode`() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.isSignUp == false)
        #expect(viewModel.submitTitle == Strings.Auth.signIn)
    }

    @Test(arguments: [
        (email: "", password: "", expected: false),
        (email: "user@example.com", password: "", expected: false),
        (email: "", password: "x", expected: false),
        // Sign-in intentionally accepts weak passwords — accounts may predate the policy.
        (email: "user@example.com", password: "x", expected: true)
    ])
    func `sign-in validity only needs both fields filled`(email: String, password: String, expected: Bool) {
        let (viewModel, _) = makeViewModel()
        viewModel.email = email
        viewModel.password = password

        #expect(viewModel.isFormValid == expected)
    }

    @Test(arguments: [
        (name: "Test", email: "user@example.com", password: "Password1", expected: true),
        (name: "", email: "user@example.com", password: "Password1", expected: false),
        (name: "Test", email: "", password: "Password1", expected: false),
        (name: "Test", email: "not-an-email", password: "Password1", expected: false),
        (name: "Test", email: "user@example.com", password: "password1", expected: false),
        (name: "Test", email: "user@example.com", password: "Pass1", expected: false)
    ])
    func `sign-up validity enforces the email and password policies`(
        name: String, email: String, password: String, expected: Bool
    ) {
        let (viewModel, _) = makeViewModel()
        viewModel.toggleMode()
        viewModel.name = name
        viewModel.email = email
        viewModel.password = password

        #expect(viewModel.isFormValid == expected)
    }

    /// Sign-in leaves the address to the server — an account may predate the policy.
    @Test func `sign-in validity ignores the email policy`() {
        let (viewModel, _) = makeViewModel()
        viewModel.email = "not-an-email"
        viewModel.password = "secret"

        #expect(viewModel.isFormValid)
        #expect(viewModel.emailValidationMessage == nil)
    }

    @Test func `the email hint stays hidden until something is typed`() {
        let (viewModel, _) = makeViewModel()
        viewModel.toggleMode()

        #expect(viewModel.emailValidationMessage == nil)

        viewModel.email = "user@"
        #expect(viewModel.emailValidationMessage == Strings.Auth.invalidEmail)

        viewModel.email = "user@example.com"
        #expect(viewModel.emailValidationMessage == nil)
    }

    @Test func `password requirement flags mirror the policy`() {
        let (viewModel, _) = makeViewModel()
        viewModel.password = "abcdefgh"

        #expect(viewModel.passwordHasMinLength)
        #expect(!viewModel.passwordHasUppercase)
        #expect(!viewModel.passwordHasNumber)
    }

    // MARK: - Mode toggling

    @Test func `toggleMode flips the mode and its submit title`() {
        let (viewModel, _) = makeViewModel()
        viewModel.toggleMode()

        #expect(viewModel.isSignUp)
        #expect(viewModel.submitTitle == Strings.Auth.signUp)
    }

    @Test func `toggleMode clears a previous error`() async {
        let (viewModel, auth) = makeViewModel()
        auth.signInError = MockError.generic("boom")
        viewModel.email = "user@example.com"
        viewModel.password = "x"
        await viewModel.authenticate()
        #expect(viewModel.errorMessage != nil)

        viewModel.toggleMode()
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `toggleMode clears a previous info message`() async {
        let (viewModel, auth) = makeViewModel()
        auth.signUpError = AuthServiceError.emailConfirmationRequired
        viewModel.toggleMode()
        fill(viewModel)
        await viewModel.authenticate()
        #expect(viewModel.infoMessage != nil)

        viewModel.toggleMode()
        #expect(viewModel.infoMessage == nil)
    }

    // MARK: - authenticate routing

    @Test func `authenticate signs in when in sign-in mode`() async {
        let (viewModel, auth) = makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        await viewModel.authenticate()

        #expect(auth.signInCalls.count == 1)
        #expect(auth.signInCalls.first?.email == "user@example.com")
        #expect(auth.signInCalls.first?.password == "secret")
        #expect(auth.signUpCalls.isEmpty)
    }

    @Test func `authenticate signs up when in sign-up mode`() async {
        let (viewModel, auth) = makeViewModel()
        viewModel.toggleMode()
        fill(viewModel)

        await viewModel.authenticate()

        #expect(auth.signUpCalls.count == 1)
        #expect(auth.signUpCalls.first?.name == "Test User")
        #expect(auth.signInCalls.isEmpty)
    }

    @Test func `authenticate clears the session-expired message before trying`() async {
        let (viewModel, auth) = makeViewModel(sessionExpiredMessage: "expired")
        #expect(viewModel.sessionExpiredMessage == "expired")

        viewModel.email = "user@example.com"
        viewModel.password = "secret"
        await viewModel.authenticate()

        #expect(auth.clearSessionExpiredMessageCallCount == 1)
        #expect(viewModel.sessionExpiredMessage == nil)
    }

    // MARK: - Loading and outcomes

    @Test func `authenticate raises and lowers isLoading`() async {
        let (viewModel, auth) = makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        var loadingDuringCall: Bool?
        auth.onCall = { loadingDuringCall = viewModel.isLoading }

        await viewModel.authenticate()

        #expect(loadingDuringCall == true)
        #expect(viewModel.isLoading == false)
    }

    @Test func `authenticate ignores a reentrant call while loading`() async {
        let (viewModel, auth) = makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        // A second submit landing mid-flight must not issue another request.
        auth.onCall = { await viewModel.authenticate() }

        await viewModel.authenticate()
        #expect(auth.signInCalls.count == 1)
    }

    @Test func `authenticate surfaces a failure as an error message`() async {
        let (viewModel, auth) = makeViewModel()
        auth.signInError = APIError.serverError
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        await viewModel.authenticate()

        #expect(viewModel.errorMessage == APIError.serverError.userFacingMessage)
        #expect(viewModel.infoMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    /// Sign-up pending email confirmation is a success-ish outcome, so it must not
    /// land in the same slot the view renders in red.
    @Test func `emailConfirmationRequired becomes an info message, not an error`() async {
        let (viewModel, auth) = makeViewModel()
        auth.signUpError = AuthServiceError.emailConfirmationRequired
        viewModel.toggleMode()
        fill(viewModel)

        await viewModel.authenticate()

        #expect(viewModel.infoMessage == Strings.Auth.emailConfirmationRequired)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `a successful authenticate leaves both message slots empty`() async {
        let (viewModel, _) = makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        await viewModel.authenticate()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.infoMessage == nil)
    }

    @Test func `canSubmit is false while loading even with a valid form`() async {
        let (viewModel, auth) = makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "secret"

        var canSubmitDuringCall: Bool?
        auth.onCall = { canSubmitDuringCall = viewModel.canSubmit }

        await viewModel.authenticate()

        #expect(canSubmitDuringCall == false)
        #expect(viewModel.canSubmit == true)
    }
}
