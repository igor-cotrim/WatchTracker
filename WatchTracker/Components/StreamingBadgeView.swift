import SwiftUI

struct StreamingBadgeView: View {
    let provider: StreamingProvider

    var body: some View {
        AsyncImage(url: provider.logoURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
            case .failure:
                placeholderBadge
            case .empty:
                ProgressView()
                    .frame(width: 40, height: 40)
            @unknown default:
                placeholderBadge
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    private var placeholderBadge: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 40, height: 40)
            .overlay {
                Text(String(provider.providerName.prefix(1)))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
    }
}
