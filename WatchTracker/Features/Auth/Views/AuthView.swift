import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: AuthFocusField?

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                AuthBrandingHeader()

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
                    isDisabled: isLoading || email.isEmpty || password.isEmpty
                ) {
                    Task { await authenticate() }
                }
                .padding(.horizontal, 24)

                Button(isSignUp ? Strings.Auth.haveAccount : Strings.Auth.noAccount) {
                    isSignUp.toggle()
                    errorMessage = nil
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 14) {
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
                kind: isSignUp ? .newPassword : .password,
                focusState: $focusedField,
                focusValue: .password
            )
            .onSubmit {
                if !isLoading && !email.isEmpty && !password.isEmpty {
                    Task { await authenticate() }
                }
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

    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password)
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
