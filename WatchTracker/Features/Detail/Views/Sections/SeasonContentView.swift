import SwiftUI

struct SeasonContentView: View {
    let season: Season
    let viewModel: MediaDetailViewModel

    var body: some View {
        if viewModel.isLoadingSeason.contains(season.seasonNumber) {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        } else if let episodes = viewModel.seasonEpisodes[season.seasonNumber] {
            Button {
                Task { await viewModel.toggleSeasonWatched(season.seasonNumber) }
            } label: {
                let allWatched = viewModel.isSeasonAllWatched(season.seasonNumber)
                Label(
                    allWatched ? "Desmarcar Temporada" : "Marcar Temporada",
                    systemImage: allWatched ? "eye.slash" : "eye"
                )
                .font(.caption.bold())
                .foregroundStyle(allWatched ? .secondary : Color.brandAccent)
            }
            .padding(.top, 8)
            .padding(.leading, 8)

            EpisodeListView(episodes: episodes, seasonNumber: season.seasonNumber, viewModel: viewModel)
        }
    }
}
