import SwiftUI

struct SeasonContentView: View {
    let season: Season
    let viewModel: MediaDetailViewModel

    var body: some View {
        if viewModel.isLoadingSeason.contains(season.seasonNumber) {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        } else if let episodes = viewModel.seasonEpisodes[season.seasonNumber] {
            Divider()

            let allWatched = viewModel.isSeasonAllWatched(season.seasonNumber)
            HStack {
                Spacer()
                Button {
                    Task { await viewModel.toggleSeasonWatched(season.seasonNumber) }
                } label: {
                    Label(
                        allWatched ? Strings.Detail.seasonUnmarkWatched : Strings.Detail.seasonMarkWatched,
                        systemImage: allWatched ? "eye.slash" : "eye"
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(allWatched ? Color(.secondaryLabel) : Color.brandAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(allWatched ? Color(.systemGray5) : Color.brandAccent.opacity(0.12))
                    .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.vertical, 10)

            EpisodeListView(episodes: episodes, seasonNumber: season.seasonNumber, viewModel: viewModel)
        }
    }
}
