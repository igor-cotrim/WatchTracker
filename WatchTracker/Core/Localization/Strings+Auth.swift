import Foundation

extension Strings {
    // MARK: - Auth

    enum Auth {
        static var name: String { String(localized: "auth.name") }
        static var namePlaceholder: String { String(localized: "auth.name_placeholder") }
        static var email: String { String(localized: "auth.email") }
        static var password: String { String(localized: "auth.password") }
        static var signIn: String { String(localized: "auth.sign_in") }
        static var signUp: String { String(localized: "auth.sign_up") }
        static var haveAccount: String { String(localized: "auth.have_account") }
        static var noAccount: String { String(localized: "auth.no_account") }
        static var haveAccountPrefix: String { String(localized: "auth.have_account_prefix") }
        static var noAccountPrefix: String { String(localized: "auth.no_account_prefix") }
        static var trackYourShows: String { String(localized: "auth.track_your_shows") }

        static var welcomeTitle: String { String(localized: "auth.welcome_title") }
        static var welcomeSubtitle: String { String(localized: "auth.welcome_subtitle") }
        static var registerTitle: String { String(localized: "auth.register_title") }
        static var registerSubtitle: String { String(localized: "auth.register_subtitle") }

        static var passwordReqMinLength: String { String(localized: "auth.password_req_min_length") }
        static var passwordReqUppercase: String { String(localized: "auth.password_req_uppercase") }
        static var passwordReqNumber: String { String(localized: "auth.password_req_number") }

        static var forgotPassword: String { String(localized: "auth.forgot_password") }
        static var forgotPasswordTitle: String { String(localized: "auth.forgot_password_title") }
        static var forgotPasswordMessage: String { String(localized: "auth.forgot_password_message") }
        static var sendCode: String { String(localized: "auth.send_code") }
        static var resetCodeInstructions: String { String(localized: "auth.reset_code_instructions") }
        static var resetCodePlaceholder: String { String(localized: "auth.reset_code_placeholder") }
        static var newPasswordPlaceholder: String { String(localized: "auth.new_password_placeholder") }
        static var resetPasswordButton: String { String(localized: "auth.reset_password_button") }
        static var passwordUpdated: String { String(localized: "auth.password_updated") }
        static var passwordUpdatedHint: String { String(localized: "auth.password_updated_hint") }

        static var sessionExpired: String { String(localized: "auth.session_expired") }
        static var emailConfirmationRequired: String {
            String(localized: "auth.email_confirmation_required")
        }
    }
}
