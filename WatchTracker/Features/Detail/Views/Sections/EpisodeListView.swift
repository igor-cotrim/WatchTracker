import SwiftUI

struct EpisodeListView: View {
    let episodes: [Episode]
    let seasonNumber: Int
    let viewModel: MediaDetailViewModel

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(episodes) { episode in
                HStack(spacing: 12) {
                    AsyncImage(url: episode.stillURL) { image in
                        image.resizable().aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        SkeletonView()
                    }
                    .frame(width: 80, height: 45)
                    .clipShape(.rect(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("E\(episode.episodeNumber) — \(episode.name)")
                            .font(.subheadline)
                            .lineLimit(1)

                        if let airDate = episode.airDate {
                            Text(airDate)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        Task { await viewModel.toggleEpisodeWatched(season: seasonNumber, episode: episode.episodeNumber) }
                    } label: {
                        Image(systemName: episode.isWatched ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(episode.isWatched ? Color.brandPrimary : .secondary)
                    }
                    .accessibilityLabel("Episódio \(episode.episodeNumber), \(episode.name)")
                    .accessibilityValue(episode.isWatched ? "Assistido" : "Não assistido")
                    .accessibilityHint("Toque para \(episode.isWatched ? "desmarcar" : "marcar") como assistido")
                }
                .padding(.vertical, 6)
                .padding(.leading, 8)
            }
        }
        .padding(.top, 8)
    }
}
