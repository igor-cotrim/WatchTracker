import SwiftUI

struct DetailWhereToWatchSection: View {
    let media: MediaDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: Strings.Detail.whereToWatch)
                .font(.headline)

            if let region = media.watchProviders?.results?["BR"],
               let providers = region.flatrate, !providers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(providers) { provider in
                            Button {
                                open(provider: provider, region: region)
                            } label: {
                                StreamingBadgeView(provider: provider)
                            }
                            .buttonStyle(PressedButtonStyle())
                            .accessibilityHint(Strings.Detail.openInProviderHint)
                        }
                    }
                }
            } else {
                Text(verbatim: Strings.Detail.whereToWatchUnavailable)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func open(provider: StreamingProvider, region: WatchProviderRegion) {
        guard let link = ProviderLinkBuilder.link(
            for: provider,
            title: media.displayTitle,
            justWatchLink: region.link
        ) else { return }

        guard let appURL = link.appURL else {
            UIApplication.shared.open(link.webURL)
            return
        }

        UIApplication.shared.open(appURL) { opened in
            if !opened {
                UIApplication.shared.open(link.webURL)
            }
        }
    }
}
