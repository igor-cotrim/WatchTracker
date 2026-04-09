import SwiftUI

struct WatchlistView: View {
    let viewModel: WatchlistViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .transition(.opacity)
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        await viewModel.fetchWatchlist()
                    }
                    .transition(.opacity)
                } else if viewModel.filteredWatchlist.isEmpty {
                    emptyState
                        .transition(.opacity)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredWatchlist) { item in
                            NavigationLink {
                                MediaDetailView(mediaType: item.mediaType, mediaId: item.tmdbId)
                            } label: {
                                WatchlistCardView(item: item)
                            }
                            .buttonStyle(PressedButtonStyle())
                        }
                    }
                    .padding()
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.22), value: viewModel.filteredWatchlist.count)
        }
        .refreshable {
            await viewModel.fetchWatchlist()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(verbatim: Strings.Watchlist.emptyTitle)
                .font(.headline)
            Text(verbatim: Strings.Watchlist.emptySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}
