import SwiftUI

struct UpcomingRow: View {
    let item: UpcomingItem

    var body: some View {
        ZStack {
            NavigationLink {
                MediaDetailView(mediaType: .tv, mediaId: item.tmdbId)
            } label: {
                EmptyView()
            }
            .opacity(0)

            HStack(spacing: 14) {
                poster

                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: item.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .lineLimit(1)

                    Text(verbatim: Strings.Watching.episodeLabel(
                        season: item.nextEpisode.seasonNumber,
                        episode: item.nextEpisode.episodeNumber
                    ))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                    Text(verbatim: item.nextEpisode.name)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                airDateIndicator
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
    }

    private var poster: some View {
        AsyncImage(url: item.posterURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                SkeletonView()
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var airDateIndicator: some View {
        let days = item.nextEpisode.daysUntilAir
        let provider = item.watchProviders.first

        VStack(alignment: .trailing, spacing: 4) {
            if let provider {
                Text(provider)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            switch days {
            case 0:
                Text(Strings.Upcoming.today)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary, in: Capsule())

            case 1:
                Text(Strings.Upcoming.tomorrow)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange, in: Capsule())

            default:
                VStack(spacing: 0) {
                    Text("\(days)")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text(Strings.Upcoming.daysAway(days).components(separatedBy: " ").last ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }
        }
        .frame(minWidth: 52, alignment: .trailing)
    }
}
