import Foundation

@Observable
@MainActor
final class ForgotPasswordViewModel {
    enum Step: Equatable {
        case email
        case code
    }

    var email: String
    var code = ""
    var newPassword = ""

    private(set) var step: Step = .email
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var didReset = false

    private let auth: any AuthServiceProtocol

    init(auth: any AuthServiceProtocol, prefillEmail: String = "") {
        self.auth = auth
        self.email = prefillEmail
    }

    // MARK: - Derived state

    var passwordHasMinLength: Bool { PasswordPolicy.hasMinLength(newPassword) }
    var passwordHasUppercase: Bool { PasswordPolicy.hasUppercase(newPassword) }
    var passwordHasNumber: Bool { PasswordPolicy.hasNumber(newPassword) }

    var canSendCode: Bool { !isLoading && !email.isEmpty }
    var canConfirmReset: Bool { !isLoading && !code.isEmpty && PasswordPolicy.isValid(newPassword) }

    // MARK: - Actions

    func sendCode() async {
        guard canSendCode else { return }

        isLoading = true
        errorMessage = nil
        do {
            try await auth.resetPassword(email: email)
            step = .code
        } catch {
            errorMessage = error.userFacingMessage
        }
        isLoading = false
    }

    func confirmReset() async {
        guard canConfirmReset else { return }

        isLoading = true
        errorMessage = nil
        do {
            try await auth.confirmPasswordReset(email: email, code: code, newPassword: newPassword)
            didReset = true
        } catch {
            errorMessage = error.userFacingMessage
        }
        isLoading = false
    }
}
