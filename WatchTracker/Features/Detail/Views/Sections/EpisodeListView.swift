import SwiftUI

struct EpisodeListView: View {
    let episodes: [Episode]
    let seasonNumber: Int
    let viewModel: MediaDetailViewModel

    @State private var hapticTrigger = 0

    private func watchButtonColor(for episode: Episode) -> Color {
        guard episode.hasAired else { return Color.secondary.opacity(0.4) }
        return episode.isWatched ? Color.brandPrimary : Color.secondary
    }

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
                        Image(systemName: episode.hasAired
                              ? (episode.isWatched ? "checkmark.circle.fill" : "circle")
                              : "lock.circle")
                            .font(.title3)
                            .foregroundStyle(watchButtonColor(for: episode))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .disabled(!episode.hasAired)
                    .accessibilityLabel(Strings.Episode.accessibilityLabel(number: episode.episodeNumber, name: episode.name))
                    .accessibilityValue(episode.hasAired
                                        ? (episode.isWatched ? Strings.Episode.accessibilityWatched : Strings.Episode.accessibilityNotWatched)
                                        : Strings.Episode.accessibilityNotReleased)
                    .accessibilityHint(episode.hasAired
                                       ? (episode.isWatched ? Strings.Episode.accessibilityMarkUnwatched : Strings.Episode.accessibilityMarkWatched)
                                       : "")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)

                if episode.id != episodes.last?.id {
                    Divider()
                        .padding(.leading, 120)
                }
            }
        }
        .padding(.bottom, 4)
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }
}
