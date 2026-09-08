import SwiftUI

struct MediaDetailView: View {
    let mediaType: MediaType
    let mediaId: Int

    /// Read from the environment rather than taken through `init`: this screen is opened
    /// from eight different places (rows, grids, the cast carousel, a notification tap),
    /// and none of them should have to carry a container just to pass it on.
    @Environment(AppContainer.self) private var container
    @State private var viewModel: MediaDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 400)
            }
        }
        .task {
            let viewModel = viewModel ?? container.makeMediaDetailViewModel(type: mediaType, id: mediaId)
            self.viewModel = viewModel
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: MediaDetailViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                case .loaded(let media):
                    loaded(media, viewModel: viewModel)
                case .failed(let message):
                    ErrorStateView(message: message) {
                        await viewModel.load()
                    }
                }
            }
            .onChange(of: viewModel.scrollTargetSeason) { _, target in
                guard let target else { return }
                withAnimation {
                    proxy.scrollTo(target, anchor: .top)
                }
                viewModel.didScrollToSeason()
            }
        }
        .navigationTitle(viewModel.media?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.media != nil, viewModel.userRating != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    shareButton(viewModel)
                }
            }
        }
        .sheet(isPresented: shareBinding(viewModel)) {
            if let item = viewModel.shareItem {
                ShareSheet(items: [item.image])
                    .ignoresSafeArea()
            }
        }
        .alert(
            Strings.Detail.actionErrorTitle,
            isPresented: actionErrorBinding(viewModel),
            presenting: viewModel.actionError
        ) { _ in
            Button(Strings.Common.ok) { viewModel.dismissActionError() }
        } message: { message in
            Text(verbatim: message)
        }
    }

    @ViewBuilder
    private func loaded(_ media: MediaDetail, viewModel: MediaDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            DetailHeaderSection(media: media)

            VStack(alignment: .leading, spacing: 16) {
                DetailTitleSection(media: media)

                DetailWatchlistSection(viewModel: viewModel, mediaType: mediaType)

                if let trailer = media.trailer {
                    DetailTrailerButton(trailer: trailer, viewModel: viewModel)
                }

                DetailRatingSection(viewModel: viewModel, mediaType: mediaType)

                DetailWhereToWatchSection(media: media, viewModel: viewModel)

                DetailSynopsisSection(media: media)

                if let cast = media.credits?.cast, !cast.isEmpty {
                    DetailCastSection(cast: cast)
                }

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
    }

    private func shareButton(_ viewModel: MediaDetailViewModel) -> some View {
        Button {
            Task { await viewModel.shareRating() }
        } label: {
            if viewModel.isRenderingShare {
                ProgressView()
            } else {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .disabled(viewModel.isRenderingShare)
        .accessibilityLabel(Strings.Rating.shareAccessibility)
    }

    /// The card lives on the view model (rendering it fetches the poster), so presentation
    /// is a plain read-through binding rather than `.sheet(item:)` over view state.
    private func shareBinding(_ viewModel: MediaDetailViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.shareItem != nil },
            set: { if !$0 { viewModel.dismissShareCard() } }
        )
    }

    private func actionErrorBinding(_ viewModel: MediaDetailViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.actionError != nil },
            set: { if !$0 { viewModel.dismissActionError() } }
        )
    }
}

#Preview {
    NavigationStack {
        MediaDetailView(mediaType: .movie, mediaId: 550)
    }
    .environment(AppContainer.preview)
}
