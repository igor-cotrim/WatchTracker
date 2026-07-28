import SwiftUI

struct SeasonHeaderView: View {
    let season: Season
    let viewModel: MediaDetailViewModel

    var body: some View {
        let isExpanded = viewModel.expandedSeasons.contains(season.seasonNumber)

        Button {
            let willExpand = !isExpanded
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleExpanded(season.seasonNumber)
            }
            if willExpand {
                Task { await viewModel.loadSeasonIfNeeded(season.seasonNumber) }
            }
        } label: {
            HStack {
                AsyncImage(url: season.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(2/3, contentMode: .fill)
                    default:
                        posterPlaceholder
                    }
                }
                .frame(width: 60, height: 90)
                .clipShape(.rect(cornerRadius: 8))
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: season.name)
                        .font(.callout.bold())
                    Text(verbatim: Strings.Detail.seasonEpisodesCount(season.episodeCount ?? season.episodes?.count ?? 0))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.tertiary)
                    .font(.footnote)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "film")
                    .font(.caption)
                    .foregroundStyle(Color(.systemGray3))
            }
    }
}
