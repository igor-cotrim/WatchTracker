import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo / Title
                VStack(spacing: 8) {
                    Image(systemName: "play.tv.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.brandPrimary)

                    Text(verbatim: "WatchTracker")
                        .font(.largeTitle.bold())
                }

                // Form
                VStack(spacing: 16) {
                    TextField(Strings.Auth.email, text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField(Strings.Auth.password, text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal, 32)

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Action Button
                Button {
                    Task { await authenticate() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(verbatim: isSignUp ? Strings.Auth.signUp : Strings.Auth.signIn)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .padding(.horizontal, 32)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                // Toggle
                Button(isSignUp ? Strings.Auth.haveAccount : Strings.Auth.noAccount) {
                    isSignUp.toggle()
                    errorMessage = nil
                }
                .font(.footnote)

                Spacer()
            }
        }
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
