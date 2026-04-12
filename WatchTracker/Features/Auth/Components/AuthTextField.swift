import SwiftUI

enum AuthFieldKind {
    case email
    case password
    case newPassword
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let kind: AuthFieldKind

    var body: some View {
        field
            .textFieldStyle(.plain)
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
    }

    @ViewBuilder
    private var field: some View {
        switch kind {
        case .email:
            TextField(placeholder, text: $text)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
        case .password:
            SecureField(placeholder, text: $text)
                .textContentType(.password)
        case .newPassword:
            SecureField(placeholder, text: $text)
                .textContentType(.newPassword)
        }
    }
}
