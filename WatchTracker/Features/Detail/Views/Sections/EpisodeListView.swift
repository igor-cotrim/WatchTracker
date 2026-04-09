import SwiftUI

struct EpisodeListView: View {
    let episodes: [Episode]
    let seasonNumber: Int
    let viewModel: MediaDetailViewModel

    @State private var hapticTrigger = 0

    private var episodePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "play.rectangle")
                    .foregroundStyle(.secondary)
            }
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(episodes) { episode in
                HStack(spacing: 12) {
                    Group {
                        if let stillURL = episode.stillURL {
                            AsyncImage(url: stillURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                                case .empty:
                                    SkeletonView()
                                default:
                                    episodePlaceholder
                                }
                            }
                        } else {
                            episodePlaceholder
                        }
                    }
                    .frame(width: 80, height: 45)
                    .clipShape(.rect(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: Strings.Episode.label(number: episode.episodeNumber, name: episode.name))
                            .font(.subheadline)
                            .lineLimit(1)

                        if let airDate = episode.airDate {
                            Text(verbatim: airDate)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        hapticTrigger += 1
                        Task { await viewModel.toggleEpisodeWatched(season: seasonNumber, episode: episode.episodeNumber) }
                    } label: {
                        Image(systemName: episode.isWatched ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(episode.isWatched ? Color.brandPrimary : .secondary)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: episode.isWatched)
                    }
                    .accessibilityLabel(Strings.Episode.accessibilityLabel(number: episode.episodeNumber, name: episode.name))
                    .accessibilityValue(episode.isWatched ? Strings.Episode.accessibilityWatched : Strings.Episode.accessibilityNotWatched)
                    .accessibilityHint(episode.isWatched ? Strings.Episode.accessibilityMarkUnwatched : Strings.Episode.accessibilityMarkWatched)
                }
                .padding(.vertical, 6)
                .padding(.leading, 8)
            }
        }
        .padding(.top, 8)
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }
}
