import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @FocusState private var focusedField: AuthFocusField?

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                AuthBrandingHeader()

                AuthModeHeader(isSignUp: isSignUp)

                formCard

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                AuthPrimaryButton(
                    title: isSignUp ? Strings.Auth.signUp : Strings.Auth.signIn,
                    isLoading: isLoading,
                    isDisabled: isLoading || !isFormValid
                ) {
                    Task { await authenticate() }
                }
                .padding(.horizontal, 24)

                toggleButton

                Spacer()
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(prefillEmail: email)
        }
    }

    private var formCard: some View {
        VStack(spacing: 14) {
            if isSignUp {
                AuthTextField(
                    placeholder: Strings.Auth.namePlaceholder,
                    text: $name,
                    kind: .name,
                    focusState: $focusedField,
                    focusValue: .name
                )
                .onSubmit { focusedField = .email }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            AuthTextField(
                placeholder: Strings.Auth.email,
                text: $email,
                kind: .email,
                focusState: $focusedField,
                focusValue: .email
            )
            .onSubmit { focusedField = .password }

            AuthTextField(
                placeholder: Strings.Auth.password,
                text: $password,
                kind: .password,
                focusState: $focusedField,
                focusValue: .password
            )
            .onSubmit {
                if !isLoading && isFormValid {
                    Task { await authenticate() }
                }
            }

            if isSignUp {
                PasswordRequirementsView(
                    hasMinLength: passwordHasMinLength,
                    hasUppercase: passwordHasUppercase,
                    hasNumber: passwordHasNumber
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !isSignUp {
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
                isSignUp.toggle()
                errorMessage = nil
            }
        } label: {
            Text(isSignUp ? Strings.Auth.haveAccountPrefix : Strings.Auth.noAccountPrefix)
                .foregroundStyle(.secondary)
            + Text(verbatim: " ")
            + Text(isSignUp ? Strings.Auth.signIn : Strings.Auth.signUp)
                .foregroundStyle(Color.brandPrimary)
                .fontWeight(.semibold)
        }
        .font(.footnote)
    }

    // MARK: - Validation

    private var passwordHasMinLength: Bool { password.count >= 8 }
    private var passwordHasUppercase: Bool {
        password.range(of: "[A-Z]", options: .regularExpression) != nil
    }
    private var passwordHasNumber: Bool {
        password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    private var isPasswordValid: Bool {
        passwordHasMinLength && passwordHasUppercase && passwordHasNumber
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && !email.isEmpty && isPasswordValid
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password, name: name)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
}
