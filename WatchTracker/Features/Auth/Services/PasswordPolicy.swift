import Foundation

/// The password rules shown by `PasswordRequirementsView` and enforced on sign-up
/// and password reset. Sign-in deliberately does not apply them — existing accounts
/// may predate the current rules.
enum PasswordPolicy {
    static let minimumLength = 8

    static func hasMinLength(_ password: String) -> Bool {
        password.count >= minimumLength
    }

    static func hasUppercase(_ password: String) -> Bool {
        password.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    static func hasNumber(_ password: String) -> Bool {
        password.range(of: "[0-9]", options: .regularExpression) != nil
    }

    static func isValid(_ password: String) -> Bool {
        hasMinLength(password) && hasUppercase(password) && hasNumber(password)
    }
}
