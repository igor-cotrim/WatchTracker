import SwiftUI

struct ProvidersRowSection: View {
    let providers: [StreamingProvider]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: Strings.Discover.providers)
                .font(.title3.bold())
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(providers) { provider in
                        NavigationLink {
                            ProviderBrowseView(provider: provider)
                        } label: {
                            VStack(spacing: 4) {
                                AsyncImage(url: provider.logoURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    default:
                                        RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5))
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(.rect(cornerRadius: 10))

                                Text(verbatim: provider.providerName)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                        .buttonStyle(PressedButtonStyle())
                        .accessibilityLabel(Strings.Discover.browseAccessibility(provider.providerName))
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}
