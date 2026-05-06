import SwiftUI

struct DetailWhereToWatchSection: View {
    let media: MediaDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: Strings.Detail.whereToWatch)
                .font(.headline)

            if let providers = media.watchProviders?.results?["BR"]?.flatrate, !providers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(providers) { provider in
                            StreamingBadgeView(provider: provider)
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
}
