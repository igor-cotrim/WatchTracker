import SwiftUI

struct MediaDetailView: View {
    let mediaType: MediaType
    let mediaId: Int

    @State private var viewModel = MediaDetailViewModel(
        mediaDetailService: MediaDetailService(),
        watchlistService: WatchlistService(),
        store: .shared
    )
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if let media = viewModel.media {
                    VStack(alignment: .leading, spacing: 20) {
                        DetailHeaderSection(media: media)

                        VStack(alignment: .leading, spacing: 16) {
                            DetailTitleSection(media: media)

                            DetailWatchlistSection(viewModel: viewModel, mediaType: mediaType)

                            DetailWhereToWatchSection(media: media)

                            DetailSynopsisSection(media: media)

                            if let seasons = media.seasons, !seasons.isEmpty {
                                DetailSeasonsSection(seasons: seasons, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)

                        if !viewModel.recommendations.isEmpty {
                            MediaRowSection(
                                title: Strings.Detail.recommendations,
                                items: viewModel.recommendations
                            )
                        }
                    }
                    .padding(.bottom, 32)
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        await viewModel.fetchDetails(type: mediaType, id: mediaId)
                        await viewModel.checkWatchlistStatus()
                    }
                }
            }
            .onChange(of: viewModel.scrollTargetSeason) { _, target in
                guard let target else { return }
                withAnimation {
                    proxy.scrollTo(target, anchor: .top)
                }
                viewModel.scrollTargetSeason = nil
            }
        }
        .navigationTitle(viewModel.media?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let details: () = viewModel.fetchDetails(type: mediaType, id: mediaId)
            async let recs: () = viewModel.fetchRecommendations(type: mediaType, id: mediaId)
            _ = await (details, recs)
            await viewModel.checkWatchlistStatus()
        }
    }
}

#Preview {
    NavigationStack {
        MediaDetailView(mediaType: .movie, mediaId: 550)
    }
}
