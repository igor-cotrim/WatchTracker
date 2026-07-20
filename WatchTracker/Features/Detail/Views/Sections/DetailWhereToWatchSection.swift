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
            trackTap(provider: provider, openedVia: "web")
            UIApplication.shared.open(link.webURL)
            return
        }

        UIApplication.shared.open(appURL) { opened in
            trackTap(provider: provider, openedVia: opened ? "app_deeplink" : "web_fallback")
            if !opened {
                UIApplication.shared.open(link.webURL)
            }
        }
    }

    private func trackTap(provider: StreamingProvider, openedVia: String) {
        AnalyticsService.shared.capture(.providerLinkTapped, properties: [
            "provider_id": provider.providerId,
            "provider_name": provider.providerName,
            "title": media.displayTitle,
            "opened_via": openedVia
        ])
    }
}
