import SwiftUI

struct AuthModeHeader: View {
    let isSignUp: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(isSignUp ? Strings.Auth.registerTitle : Strings.Auth.welcomeTitle)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(isSignUp ? Strings.Auth.registerSubtitle : Strings.Auth.welcomeSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }
}
