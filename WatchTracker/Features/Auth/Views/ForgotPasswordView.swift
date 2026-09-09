import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ForgotPasswordViewModel
    @FocusState private var focusedField: AuthField?

    init(auth: any AuthServiceProtocol, prefillEmail: String = "") {
        _viewModel = State(wrappedValue: ForgotPasswordViewModel(auth: auth, prefillEmail: prefillEmail))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.didReset {
                    successState
                } else {
                    switch viewModel.step {
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
            .animation(.default, value: viewModel.step)
            .animation(.default, value: viewModel.didReset)
            .onChange(of: viewModel.step) { _, step in
                if step == .code { focusedField = .code }
            }
        }
    }

    // MARK: - Step 1: email

    private var emailStep: some View {
        VStack(spacing: 24) {
            instructions(Strings.Auth.forgotPasswordMessage)

            AuthTextField(
                placeholder: Strings.Auth.email,
                text: $viewModel.email,
                field: .email,
                focusState: $focusedField
            )
            .onSubmit { Task { await viewModel.sendCode() } }

            errorText

            AuthPrimaryButton(
                title: Strings.Auth.sendCode,
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.canSendCode
            ) {
                Task { await viewModel.sendCode() }
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
                    text: $viewModel.code,
                    field: .code,
                    focusState: $focusedField
                )
                .onSubmit { focusedField = .password }

                AuthTextField(
                    placeholder: Strings.Auth.newPasswordPlaceholder,
                    text: $viewModel.newPassword,
                    field: .password,
                    focusState: $focusedField
                )

                PasswordRequirementsView(
                    hasMinLength: viewModel.passwordHasMinLength,
                    hasUppercase: viewModel.passwordHasUppercase,
                    hasNumber: viewModel.passwordHasNumber
                )
            }

            errorText

            AuthPrimaryButton(
                title: Strings.Auth.resetPasswordButton,
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.canConfirmReset
            ) {
                Task { await viewModel.confirmReset() }
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
        if let errorMessage = viewModel.errorMessage {
            Text(verbatim: errorMessage)
                .font(.caption)
                .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ForgotPasswordView(auth: PreviewAuthService(), prefillEmail: "user@example.com")
}
