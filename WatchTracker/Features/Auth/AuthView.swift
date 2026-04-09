import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Layer 0: dark cinematic background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.12),
                    Color(red: 0.12, green: 0.08, blue: 0.10),
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Layer 1: red glow orb behind the logo area
            RadialGradient(
                colors: [Color.brandPrimary.opacity(0.35), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .frame(width: 360, height: 360)
            .offset(y: -200)
            .blur(radius: 20)
            .allowsHitTesting(false)

            // Layer 2: main content
            VStack(spacing: 32) {
                Spacer()

                // Logo / Title
                VStack(spacing: 10) {
                    Image(systemName: "play.tv.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                        .shadow(color: Color.brandPrimary.opacity(0.8), radius: 20)

                    Text(verbatim: "WatchTracker")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Track what you watch.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Glass form card
                VStack(spacing: 14) {
                    TextField(Strings.Auth.email, text: $email)
                        .textFieldStyle(.plain)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)

                    SecureField(Strings.Auth.password, text: $password)
                        .textFieldStyle(.plain)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
                .colorScheme(.dark)
                .padding(.horizontal, 24)

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Action Button
                Button {
                    Task { await authenticate() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(verbatim: isSignUp ? Strings.Auth.signUp : Strings.Auth.signIn)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(
                        isLoading || email.isEmpty || password.isEmpty
                            ? Color.brandPrimary.opacity(0.4)
                            : Color.brandPrimary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.brandPrimary.opacity(0.5), radius: 10, y: 4)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 24)

                // Toggle
                Button(isSignUp ? Strings.Auth.haveAccount : Strings.Auth.noAccount) {
                    isSignUp.toggle()
                    errorMessage = nil
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
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
