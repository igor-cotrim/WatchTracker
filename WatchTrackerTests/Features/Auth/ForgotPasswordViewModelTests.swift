import Foundation
import Testing
@testable import WatchTracker

@MainActor
@Suite("ForgotPasswordViewModel", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct ForgotPasswordViewModelTests {

    private func makeViewModel(prefillEmail: String = "user@example.com")
        -> (ForgotPasswordViewModel, MockAuthService) {
        let auth = MockAuthService()
        return (ForgotPasswordViewModel(auth: auth, prefillEmail: prefillEmail), auth)
    }

    /// Advances a view model to the code step with a valid reset form.
    private func atCodeStep() async -> (ForgotPasswordViewModel, MockAuthService) {
        let (viewModel, auth) = makeViewModel()
        await viewModel.sendCode()
        viewModel.code = "123456"
        viewModel.newPassword = "Password1"
        return (viewModel, auth)
    }

    // MARK: - Initial state

    @Test func `starts on the email step with the prefilled address`() {
        let (viewModel, _) = makeViewModel(prefillEmail: "prefill@example.com")

        #expect(viewModel.step == .email)
        #expect(viewModel.email == "prefill@example.com")
        #expect(viewModel.didReset == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `an empty prefill leaves the email field blank`() {
        let (viewModel, _) = makeViewModel(prefillEmail: "")
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.canSendCode == false)
    }

    // MARK: - sendCode

    @Test func `sendCode advances to the code step`() async {
        let (viewModel, auth) = makeViewModel()

        await viewModel.sendCode()

        #expect(viewModel.step == .code)
        #expect(auth.resetPasswordCalls == ["user@example.com"])
        #expect(viewModel.isLoading == false)
    }

    @Test func `sendCode keeps the email step when the request fails`() async {
        let (viewModel, auth) = makeViewModel()
        auth.resetPasswordError = APIError.serverError

        await viewModel.sendCode()

        #expect(viewModel.step == .email)
        #expect(viewModel.errorMessage == APIError.serverError.userFacingMessage)
    }

    @Test func `sendCode does nothing without an email`() async {
        let (viewModel, auth) = makeViewModel(prefillEmail: "")

        await viewModel.sendCode()

        #expect(auth.resetPasswordCalls.isEmpty)
        #expect(viewModel.step == .email)
    }

    @Test func `sendCode raises and lowers isLoading`() async {
        let (viewModel, auth) = makeViewModel()

        var loadingDuringCall: Bool?
        auth.onCall = { loadingDuringCall = viewModel.isLoading }

        await viewModel.sendCode()

        #expect(loadingDuringCall == true)
        #expect(viewModel.isLoading == false)
    }

    @Test func `sendCode clears a previous error on retry`() async {
        let (viewModel, auth) = makeViewModel()
        auth.resetPasswordError = APIError.serverError
        await viewModel.sendCode()
        #expect(viewModel.errorMessage != nil)

        auth.resetPasswordError = nil
        await viewModel.sendCode()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.step == .code)
    }

    // MARK: - canConfirmReset

    @Test(arguments: [
        (code: "", password: "Password1", expected: false),
        (code: "123456", password: "", expected: false),
        (code: "123456", password: "password1", expected: false),  // no uppercase
        (code: "123456", password: "Pass1", expected: false),      // too short
        (code: "123456", password: "Password1", expected: true)
    ])
    func `canConfirmReset requires a code and a policy-compliant password`(
        code: String, password: String, expected: Bool
    ) async {
        let (viewModel, _) = makeViewModel()
        await viewModel.sendCode()
        viewModel.code = code
        viewModel.newPassword = password

        #expect(viewModel.canConfirmReset == expected)
    }

    // MARK: - confirmReset

    @Test func `confirmReset reaches the success state`() async {
        let (viewModel, auth) = await atCodeStep()

        await viewModel.confirmReset()

        #expect(viewModel.didReset)
        #expect(auth.confirmPasswordResetCalls.count == 1)
        let call = auth.confirmPasswordResetCalls.first
        #expect(call?.email == "user@example.com")
        #expect(call?.code == "123456")
        #expect(call?.newPassword == "Password1")
    }

    @Test func `confirmReset stays on the code step when the request fails`() async {
        let (viewModel, auth) = await atCodeStep()
        auth.confirmPasswordResetError = APIError.unauthorized

        await viewModel.confirmReset()

        #expect(viewModel.didReset == false)
        #expect(viewModel.step == .code)
        #expect(viewModel.errorMessage == APIError.unauthorized.userFacingMessage)
    }

    @Test func `confirmReset does nothing when the form is incomplete`() async {
        let (viewModel, auth) = makeViewModel()
        await viewModel.sendCode()
        viewModel.code = "123456"
        viewModel.newPassword = "weak"

        await viewModel.confirmReset()

        #expect(auth.confirmPasswordResetCalls.isEmpty)
        #expect(viewModel.didReset == false)
    }

    @Test func `confirmReset raises and lowers isLoading`() async {
        let (viewModel, auth) = await atCodeStep()

        var loadingDuringCall: Bool?
        auth.onCall = { loadingDuringCall = viewModel.isLoading }

        await viewModel.confirmReset()

        #expect(loadingDuringCall == true)
        #expect(viewModel.isLoading == false)
    }

    @Test func `password requirement flags track the new password`() async {
        let (viewModel, _) = makeViewModel()
        viewModel.newPassword = "Password1"

        #expect(viewModel.passwordHasMinLength)
        #expect(viewModel.passwordHasUppercase)
        #expect(viewModel.passwordHasNumber)
    }
}
