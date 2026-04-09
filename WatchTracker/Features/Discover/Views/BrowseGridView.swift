import SwiftUI

struct BrowseGridView: View {
    let viewModel: BrowseGridViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.results.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = viewModel.errorMessage, viewModel.results.isEmpty {
                ErrorStateView(message: error) {
                    await viewModel.loadInitial()
                }
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.results) { item in
                        NavigationLink {
                            MediaDetailView(
                                mediaType: item.mediaType,
                                mediaId: item.id
                            )
                        } label: {
                            PosterCardView(
                                url: item.posterURL,
                                title: item.displayTitle
                            )
                        }
                        .buttonStyle(PressedButtonStyle())
                        .onAppear {
                            if item.id == viewModel.results.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .task {
            await viewModel.loadInitial()
        }
    }
}
