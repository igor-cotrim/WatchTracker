import SwiftUI

/// The paginated grid every "see all" link and every mood opens.
///
/// Takes a `BrowseFeed` rather than a ready-made view model: the row that links here is
/// rendered inside a `body`, and building an `@Observable` there would allocate a fresh
/// view model on every evaluation.
struct BrowseGridView: View {
    let feed: BrowseFeed

    @Environment(AppContainer.self) private var container
    @State private var viewModel: BrowseGridViewModel?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            switch viewModel?.state {
            case .loading, .none:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            case .failed(let message):
                ErrorStateView(message: message) {
                    await viewModel?.loadInitial()
                }
            case .loaded(let items) where items.isEmpty:
                // A filter combination can legitimately match nothing, which used to render
                // as a blank scroll view with no explanation.
                ContentUnavailableView(
                    Strings.DiscoverFilter.empty,
                    systemImage: "line.3.horizontal.decrease.circle"
                )
                .frame(minHeight: 300)
            case .loaded(let items):
                grid(items)
            }
        }
        .task {
            let viewModel = viewModel ?? container.makeBrowseGridViewModel(for: feed)
            self.viewModel = viewModel
            await viewModel.loadInitial()
        }
    }

    private func grid(_ items: [MediaDetail]) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                NavigationLink {
                    MediaDetailView(mediaType: item.mediaType, mediaId: item.id)
                } label: {
                    PosterCardView(url: item.posterURL, title: item.displayTitle)
                }
                .buttonStyle(PressedButtonStyle())
                .onAppear {
                    guard item.id == items.last?.id else { return }
                    Task { await viewModel?.loadMore() }
                }
            }
        }
        .padding()
    }
}
