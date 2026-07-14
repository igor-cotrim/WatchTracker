import SwiftUI

enum AuthFieldKind {
    case name
    case email
    case password
    case code
}

enum AuthFocusField {
    case name
    case email
    case password
    case code
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let kind: AuthFieldKind
    var focusState: FocusState<AuthFocusField?>.Binding
    var focusValue: AuthFocusField

    var body: some View {
        field
            .textFieldStyle(.plain)
            .padding(14)
            .background(Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var field: some View {
        switch kind {
        case .name:
            TextField(placeholder, text: $text)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .focused(focusState, equals: focusValue)
                .submitLabel(.next)
        case .email:
            TextField(placeholder, text: $text)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .focused(focusState, equals: focusValue)
                .submitLabel(.next)
        case .password:
            SecureField(placeholder, text: $text)
                .textContentType(.password)
                .focused(focusState, equals: focusValue)
                .submitLabel(.go)
        case .code:
            TextField(placeholder, text: $text)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .focused(focusState, equals: focusValue)
                .submitLabel(.next)
        }
    }
}
