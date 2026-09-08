import SwiftUI

struct DetailSeasonsSection: View {
    let seasons: [Season]
    let viewModel: MediaDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Detail.seasons)
                .font(.headline)

            ForEach(seasons.filter { ($0.episodeCount ?? 0) > 0 }) { season in
                VStack(alignment: .leading, spacing: 0) {
                    SeasonHeaderView(season: season, viewModel: viewModel)

                    if viewModel.expandedSeasons.contains(season.seasonNumber) {
                        SeasonContentView(season: season, viewModel: viewModel)
                    }
                }
                // `secondarySystemGroupedBackground` is pure white in light mode, so on this
                // plain (ungrouped) ScrollView the card had no edge at all — it only read as
                // a card in dark mode. `secondarySystemBackground` contrasts in both, and the
                // hairline stroke keeps the boundary crisp against tinted wallpapers.
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
                }
                .id(season.seasonNumber)
            }
        }
    }
}
