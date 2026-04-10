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
        VStack(spacing: 0) {
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
                    .frame(width: 96, height: 54)
                    .clipShape(.rect(cornerRadius: 6))
                    .opacity(episode.isWatched ? 0.5 : 1.0)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: Strings.Episode.label(number: episode.episodeNumber, name: episode.name))
                            .font(.subheadline)
                            .lineLimit(2)

                        if let airDate = episode.airDate {
                            Text(verbatim: airDate)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .opacity(episode.isWatched ? 0.5 : 1.0)

                    Spacer()

                    Button {
                        hapticTrigger += 1
                        Task { await viewModel.toggleEpisodeWatched(season: seasonNumber, episode: episode.episodeNumber) }
                    } label: {
                        Image(systemName: episode.isWatched ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(episode.isWatched ? Color.brandPrimary : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(Strings.Episode.accessibilityLabel(number: episode.episodeNumber, name: episode.name))
                    .accessibilityValue(episode.isWatched ? Strings.Episode.accessibilityWatched : Strings.Episode.accessibilityNotWatched)
                    .accessibilityHint(episode.isWatched ? Strings.Episode.accessibilityMarkUnwatched : Strings.Episode.accessibilityMarkWatched)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)

                if episode.id != episodes.last?.id {
                    Divider()
                        .padding(.leading, 120) // 96pt thumbnail + 12pt spacing + 12pt left padding
                }
            }
        }
        .padding(.bottom, 4)
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }
}
