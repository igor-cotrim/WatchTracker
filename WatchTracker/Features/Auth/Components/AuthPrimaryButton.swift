import SwiftUI

struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(verbatim: title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background(
                isDisabled
                    ? Color.brandPrimary.opacity(0.4)
                    : Color.brandPrimary
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.brandPrimary.opacity(0.5), radius: 10, y: 4)
        }
        .disabled(isDisabled)
    }
}
