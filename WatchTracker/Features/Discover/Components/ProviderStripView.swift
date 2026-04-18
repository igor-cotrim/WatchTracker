import SwiftUI

struct ProviderStripView: View {
    let providers: [StreamingProvider]
    let selectedProviderId: Int?
    let onSelect: (StreamingProvider?) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                allChip
                ForEach(providers) { provider in
                    providerChip(provider)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private var isAllSelected: Bool { selectedProviderId == nil }

    private var allChip: some View {
        Button {
            onSelect(nil)
        } label: {
            Text(verbatim: Strings.Discover.allProviders)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(isAllSelected ? Color.brandPrimary : Color.brandPrimary.opacity(0.12))
                .foregroundStyle(isAllSelected ? Color.white : Color.brandPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(PressedButtonStyle())
        .accessibilityLabel(Strings.Discover.allProviders)
    }

    private func providerChip(_ provider: StreamingProvider) -> some View {
        let isSelected = provider.providerId == selectedProviderId
        return Button {
            onSelect(provider)
        } label: {
            AsyncImage(url: provider.logoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                }
            }
            .frame(width: 40, height: 40)
            .padding(8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.brandPrimary.opacity(0.18) : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PressedButtonStyle())
        .accessibilityLabel(provider.providerName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
