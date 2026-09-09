import Foundation

@Observable
@MainActor
final class AuthViewModel {
    var name = ""
    var email = ""
    var password = ""

    private(set) var isSignUp = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// A non-failure outcome worth showing, currently only "confirm your email".
    /// Kept apart from `errorMessage` so the view can style it as information.
    private(set) var infoMessage: String?

    private let auth: any AuthServiceProtocol

    init(auth: any AuthServiceProtocol) {
        self.auth = auth
    }

    // MARK: - Derived state

    var sessionExpiredMessage: String? { auth.sessionExpiredMessage }

    var submitTitle: String { isSignUp ? Strings.Auth.signUp : Strings.Auth.signIn }

    var passwordHasMinLength: Bool { PasswordPolicy.hasMinLength(password) }
    var passwordHasUppercase: Bool { PasswordPolicy.hasUppercase(password) }
    var passwordHasNumber: Bool { PasswordPolicy.hasNumber(password) }

    var isEmailValid: Bool { EmailPolicy.isValid(email) }

    /// The inline hint under the email field. Stays nil while the field is still
    /// empty so a fresh form does not open already complaining.
    var emailValidationMessage: String? {
        guard isSignUp, !email.isEmpty, !isEmailValid else { return nil }
        return Strings.Auth.invalidEmail
    }

    /// Sign-in only requires both fields filled; the policies apply to new accounts only.
    var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && isEmailValid && PasswordPolicy.isValid(password)
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    var canSubmit: Bool { !isLoading && isFormValid }

    // MARK: - Actions

    func toggleMode() {
        isSignUp.toggle()
        errorMessage = nil
        infoMessage = nil
    }

    func authenticate() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        infoMessage = nil
        auth.clearSessionExpiredMessage()

        do {
            if isSignUp {
                try await auth.signUp(email: email, password: password, name: name)
            } else {
                try await auth.signIn(email: email, password: password)
            }
        } catch AuthServiceError.emailConfirmationRequired {
            infoMessage = AuthServiceError.emailConfirmationRequired.userFacingMessage
        } catch {
            errorMessage = error.userFacingMessage
        }

        isLoading = false
    }
}
