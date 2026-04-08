import SwiftUI

struct MediaDetailView: View {
    let mediaType: MediaType
    let mediaId: Int

    @State private var viewModel = MediaDetailViewModel()

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 400)
            } else if let media = viewModel.media {
                VStack(alignment: .leading, spacing: 20) {
                    DetailHeaderSection(media: media)

                    VStack(alignment: .leading, spacing: 16) {
                        DetailTitleSection(media: media, userRating: viewModel.userRating) { rating in
                            Task { await viewModel.rateMedia(rating: rating) }
                        }

                        DetailWatchlistSection(viewModel: viewModel, mediaType: mediaType)

                        DetailWhereToWatchSection(media: media)

                        DetailSynopsisSection(media: media)

                        if let seasons = media.seasons, !seasons.isEmpty {
                            DetailSeasonsSection(seasons: seasons, viewModel: viewModel)
                        }

                        if let cast = media.credits?.cast, !cast.isEmpty {
                            DetailCastSection(cast: cast)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) {
                    await viewModel.fetchDetails(type: mediaType, id: mediaId)
                    await viewModel.checkWatchlistStatus()
                }
            }
        }
        .navigationTitle(viewModel.media?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDetails(type: mediaType, id: mediaId)
            await viewModel.checkWatchlistStatus()
        }
    }
}

#Preview {
    NavigationStack {
        MediaDetailView(mediaType: .movie, mediaId: 550)
    }
}
