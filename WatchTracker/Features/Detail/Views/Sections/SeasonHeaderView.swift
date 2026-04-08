import SwiftUI

struct SeasonHeaderView: View {
    let season: Season
    let viewModel: MediaDetailViewModel

    var body: some View {
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
                .clipShape(.rect(cornerRadius: 4))

                VStack(alignment: .leading) {
                    Text(season.name)
                        .font(.subheadline.bold())
                    Text("\(season.episodeCount ?? season.episodes?.count ?? 0) episodes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: viewModel.expandedSeasons.contains(season.seasonNumber) ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}
