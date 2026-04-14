import SwiftUI

struct MediaDetailView: View {
    let mediaType: MediaType
    let mediaId: Int

    @State private var viewModel = MediaDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                    .padding(.bottom, 32)
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }
        }
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
