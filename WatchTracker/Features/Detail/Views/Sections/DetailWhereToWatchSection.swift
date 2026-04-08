import SwiftUI

struct DetailWhereToWatchSection: View {
    let media: MediaDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Onde Assistir")
                .font(.headline)

            if let providers = media.watchProviders?.results?["BR"]?.flatrate, !providers.isEmpty {
                HStack(spacing: 8) {
                    ForEach(providers) { provider in
                        StreamingBadgeView(provider: provider)
                    }
                }
            } else {
                Text("No streaming info available for your region.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
