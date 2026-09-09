import SwiftUI

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let field: AuthField
    var focusState: FocusState<AuthField?>.Binding

    var body: some View {
        input
            .textFieldStyle(.plain)
            .padding(14)
            .background(Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var input: some View {
        switch field {
        case .name:
            TextField(placeholder, text: $text)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .focused(focusState, equals: field)
                .submitLabel(.next)
        case .email:
            TextField(placeholder, text: $text)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .focused(focusState, equals: field)
                .submitLabel(.next)
        case .password:
            SecureField(placeholder, text: $text)
                .textContentType(.password)
                .focused(focusState, equals: field)
                .submitLabel(.go)
        case .code:
            TextField(placeholder, text: $text)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .focused(focusState, equals: field)
                .submitLabel(.next)
        }
    }
}
