import SwiftUI

struct SeasonHeaderView: View {
    let season: Season
    let viewModel: MediaDetailViewModel

    var body: some View {
        let isExpanded = viewModel.expandedSeasons.contains(season.seasonNumber)

        Button {
            Task { await viewModel.toggleSeason(season.seasonNumber) }
        } label: {
            HStack {
                AsyncImage(url: season.posterURL) { image in
                    image.resizable().aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    SkeletonView()
                }
                .frame(width: 50, height: 75)
                .clipShape(.rect(cornerRadius: 6))

                VStack(alignment: .leading) {
                    Text(verbatim: season.name)
                        .font(.subheadline.bold())
                    Text(verbatim: Strings.Detail.seasonEpisodesCount(season.episodeCount ?? season.episodes?.count ?? 0))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .rotationEffect(.degrees(isExpanded ? -180 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isExpanded)
            }
        }
        .buttonStyle(.plain)
    }
}
