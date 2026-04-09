import SwiftUI

struct DetailSeasonsSection: View {
    let seasons: [Season]
    let viewModel: MediaDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Temporadas")
                .font(.headline)

            ForEach(seasons) { season in
                VStack(alignment: .leading, spacing: 0) {
                    SeasonHeaderView(season: season, viewModel: viewModel)

                    if viewModel.expandedSeasons.contains(season.seasonNumber) {
                        SeasonContentView(season: season, viewModel: viewModel)
                            .transition(.opacity.combined(with: .offset(y: -4)))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.expandedSeasons.contains(season.seasonNumber))
            }
        }
    }
}
