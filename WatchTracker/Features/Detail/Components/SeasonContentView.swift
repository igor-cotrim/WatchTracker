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
            let isPending = viewModel.pendingSeasons.contains(season.seasonNumber)
            HStack {
                Spacer()
                Button {
                    Task { await viewModel.toggleSeasonWatched(season.seasonNumber) }
                } label: {
                    Label {
                        Text(allWatched ? Strings.Detail.seasonUnmarkWatched : Strings.Detail.seasonMarkWatched)
                    } icon: {
                        // Marking a whole season is the slowest write on this screen —
                        // the spinner replaces the icon so the pill keeps its width.
                        if isPending {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: allWatched ? "eye.slash" : "eye")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(allWatched ? Color(.secondaryLabel) : Color.brandAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(allWatched ? Color(.systemGray5) : Color.brandAccent.opacity(0.12))
                    .clipShape(Capsule())
                }
                .disabled(isPending)
                Spacer()
            }
            .padding(.vertical, 10)

            EpisodeListView(episodes: episodes, seasonNumber: season.seasonNumber, viewModel: viewModel)
        }
    }
}
