import SwiftUI

struct PasswordRequirementsView: View {
    let hasMinLength: Bool
    let hasUppercase: Bool
    let hasNumber: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            requirementRow(text: Strings.Auth.passwordReqMinLength, isMet: hasMinLength)
            requirementRow(text: Strings.Auth.passwordReqUppercase, isMet: hasUppercase)
            requirementRow(text: Strings.Auth.passwordReqNumber, isMet: hasNumber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func requirementRow(text: String, isMet: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? Color.brandPrimary : Color.secondary)
                .imageScale(.small)
                .animation(.easeInOut(duration: 0.2), value: isMet)

            Text(text)
                .font(.caption)
                .foregroundStyle(isMet ? .primary : .secondary)
        }
    }
}
