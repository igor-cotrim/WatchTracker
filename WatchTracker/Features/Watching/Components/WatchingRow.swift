import SwiftUI

struct WatchingRow: View {
    let item: ContinueWatchingItem
    let onMarkWatched: () async -> Void

    @State private var isMarking = false

    var body: some View {
        ZStack {
            NavigationLink {
                MediaDetailView(mediaType: .tv, mediaId: item.tmdbId)
            } label: {
                EmptyView()
            }
            .opacity(0)

            cardContent
        }
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .lineLimit(1)

                if let next = item.nextEpisode {
                    Text(verbatim: Strings.Watching.episodeLabel(season: next.seasonNumber, episode: next.episodeNumber))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(verbatim: next.name)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                guard !isMarking else { return }
                Task {
                    isMarking = true
                    await onMarkWatched()
                    isMarking = false
                }
            } label: {
                ZStack {
                    if isMarking {
                        ProgressView()
                            .tint(Color.brandPrimary)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.brandPrimary, Color.brandPrimary.opacity(0.15))
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(width: 28, height: 28)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isMarking)
            }
            .buttonStyle(.plain)
            .disabled(isMarking)
            .sensoryFeedback(.success, trigger: isMarking)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var thumbnail: some View {
        AsyncImage(url: item.stillURL ?? item.posterURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                SkeletonView()
            }
        }
        .frame(width: 120, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        )
        .overlay(alignment: .bottomLeading) {
            Image(systemName: "play.fill")
                .font(.caption2)
                .foregroundStyle(.white)
                .padding(6)
        }
    }
}
