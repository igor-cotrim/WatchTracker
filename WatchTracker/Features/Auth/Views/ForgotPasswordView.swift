import SwiftUI

struct ForgotPasswordView: View {
    private enum Step {
        case email
        case code
    }

    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .email
    @State private var email: String
    @State private var code = ""
    @State private var newPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didReset = false
    @FocusState private var focusedField: AuthFocusField?

    init(prefillEmail: String = "") {
        _email = State(initialValue: prefillEmail)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if didReset {
                    successState
                } else {
                    switch step {
                    case .email: emailStep
                    case .code: codeStep
                    }
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle(Strings.Auth.forgotPasswordTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
        }
    }

    // MARK: - Step 1: email

    private var emailStep: some View {
        VStack(spacing: 24) {
            instructions(Strings.Auth.forgotPasswordMessage)

            AuthTextField(
                placeholder: Strings.Auth.email,
                text: $email,
                kind: .email,
                focusState: $focusedField,
                focusValue: .email
            )
            .onSubmit { Task { await sendCode() } }

            errorText

            AuthPrimaryButton(
                title: Strings.Auth.sendCode,
                isLoading: isLoading,
                isDisabled: isLoading || email.isEmpty
            ) {
                Task { await sendCode() }
            }
        }
    }

    // MARK: - Step 2: code + new password

    private var codeStep: some View {
        VStack(spacing: 24) {
            instructions(Strings.Auth.resetCodeInstructions)

            VStack(spacing: 14) {
                AuthTextField(
                    placeholder: Strings.Auth.resetCodePlaceholder,
                    text: $code,
                    kind: .code,
                    focusState: $focusedField,
                    focusValue: .code
                )
                .onSubmit { focusedField = .password }

                AuthTextField(
                    placeholder: Strings.Auth.newPasswordPlaceholder,
                    text: $newPassword,
                    kind: .password,
                    focusState: $focusedField,
                    focusValue: .password
                )

                PasswordRequirementsView(
                    hasMinLength: passwordHasMinLength,
                    hasUppercase: passwordHasUppercase,
                    hasNumber: passwordHasNumber
                )
            }

            errorText

            AuthPrimaryButton(
                title: Strings.Auth.resetPasswordButton,
                isLoading: isLoading,
                isDisabled: isLoading || code.isEmpty || !isPasswordValid
            ) {
                Task { await confirmReset() }
            }
        }
    }

    private var successState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary)

            Text(Strings.Auth.passwordUpdated)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(Strings.Auth.passwordUpdatedHint)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    // MARK: - Helpers

    private func instructions(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
    }

    @ViewBuilder
    private var errorText: some View {
        if let errorMessage {
            Text(verbatim: errorMessage)
                .font(.caption)
                .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
                .multilineTextAlignment(.center)
        }
    }

    private var passwordHasMinLength: Bool { newPassword.count >= 8 }
    private var passwordHasUppercase: Bool {
        newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
    }
    private var passwordHasNumber: Bool {
        newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }
    private var isPasswordValid: Bool {
        passwordHasMinLength && passwordHasUppercase && passwordHasNumber
    }

    private func sendCode() async {
        guard !email.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.resetPassword(email: email)
            withAnimation {
                step = .code
                focusedField = .code
            }
        } catch {
            errorMessage = error.userFacingMessage
        }
        isLoading = false
    }

    private func confirmReset() async {
        guard !code.isEmpty, isPasswordValid else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.confirmPasswordReset(
                email: email,
                code: code,
                newPassword: newPassword
            )
            withAnimation { didReset = true }
        } catch {
            errorMessage = error.userFacingMessage
        }
        isLoading = false
    }
}

#Preview {
    ForgotPasswordView(prefillEmail: "user@example.com")
        .environmentObject(AuthService())
}
