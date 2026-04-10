import SwiftUI

struct DetailSeasonsSection: View {
    let seasons: [Season]
    let viewModel: MediaDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Detail.seasons)
                .font(.headline)

            ForEach(seasons) { season in
                VStack(alignment: .leading, spacing: 0) {
                    SeasonHeaderView(season: season, viewModel: viewModel)

                    if viewModel.expandedSeasons.contains(season.seasonNumber) {
                        SeasonContentView(season: season, viewModel: viewModel)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }
}
