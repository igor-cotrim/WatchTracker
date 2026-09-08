import SwiftUI

struct AuthView: View {
    private let auth: any AuthServiceProtocol

    @State private var viewModel: AuthViewModel
    @State private var showForgotPassword = false
    @FocusState private var focusedField: AuthFocusField?

    init(auth: any AuthServiceProtocol) {
        self.auth = auth
        _viewModel = State(wrappedValue: AuthViewModel(auth: auth))
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                AuthBrandingHeader()

                AuthModeHeader(isSignUp: viewModel.isSignUp)

                if let sessionExpiredMessage = viewModel.sessionExpiredMessage {
                    Text(verbatim: sessionExpiredMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                formCard

                if let errorMessage = viewModel.errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if let infoMessage = viewModel.infoMessage {
                    Text(verbatim: infoMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                AuthPrimaryButton(
                    title: viewModel.submitTitle,
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.canSubmit
                ) {
                    Task { await viewModel.authenticate() }
                }
                .padding(.horizontal, 24)

                toggleButton

                Spacer()
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(auth: auth, prefillEmail: viewModel.email)
        }
    }

    private var formCard: some View {
        VStack(spacing: 14) {
            if viewModel.isSignUp {
                AuthTextField(
                    placeholder: Strings.Auth.namePlaceholder,
                    text: $viewModel.name,
                    kind: .name,
                    focusState: $focusedField,
                    focusValue: .name
                )
                .onSubmit { focusedField = .email }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            AuthTextField(
                placeholder: Strings.Auth.email,
                text: $viewModel.email,
                kind: .email,
                focusState: $focusedField,
                focusValue: .email
            )
            .onSubmit { focusedField = .password }

            AuthTextField(
                placeholder: Strings.Auth.password,
                text: $viewModel.password,
                kind: .password,
                focusState: $focusedField,
                focusValue: .password
            )
            .onSubmit {
                if viewModel.canSubmit {
                    Task { await viewModel.authenticate() }
                }
            }

            if viewModel.isSignUp {
                PasswordRequirementsView(
                    hasMinLength: viewModel.passwordHasMinLength,
                    hasUppercase: viewModel.passwordHasUppercase,
                    hasNumber: viewModel.passwordHasNumber
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !viewModel.isSignUp {
                Button(Strings.Auth.forgotPassword) {
                    showForgotPassword = true
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .padding(.horizontal, 24)
    }

    private var toggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleMode()
            }
        } label: {
            Text(viewModel.isSignUp ? Strings.Auth.haveAccountPrefix : Strings.Auth.noAccountPrefix)
                .foregroundStyle(.secondary)
            + Text(verbatim: " ")
            + Text(viewModel.isSignUp ? Strings.Auth.signIn : Strings.Auth.signUp)
                .foregroundStyle(Color.brandPrimary)
                .fontWeight(.semibold)
        }
        .font(.footnote)
    }
}

#Preview {
    AuthView(auth: PreviewAuthService())
}
