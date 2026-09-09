import SwiftUI

struct WatchlistView: View {
    let viewModel: WatchlistViewModel
    let filter: MediaFilter

    @Environment(AppRouter.self) private var appRouter

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var items: [WatchItem] {
        viewModel.items(for: filter)
    }

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
                } else if items.isEmpty {
                    emptyState
                        .transition(.opacity)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items) { item in
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
            .animation(.easeInOut(duration: 0.22), value: items.count)
        }
        .refreshable {
            await viewModel.fetchWatchlist(forceRefresh: true)
        }
    }

    private var emptyState: some View {
        let content = emptyStateContent
        return VStack(spacing: 12) {
            Image(systemName: content.icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(verbatim: content.title)
                .font(.headline)
            Text(verbatim: content.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.allItems.isEmpty {
                Button {
                    appRouter.selectedTab = .discover
                } label: {
                    Label(Strings.Watchlist.discoverButton, systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandPrimary)
                .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var emptyStateContent: (title: String, subtitle: String, icon: String) {
        switch viewModel.selectedStatus {
        case .watching:
            return (Strings.Watchlist.emptyWatchingTitle, Strings.Watchlist.emptyWatchingSubtitle, "play.circle")
        case .planToWatch:
            return (Strings.Watchlist.emptyPlanTitle, Strings.Watchlist.emptyPlanSubtitle, "bookmark")
        case .completed:
            return (Strings.Watchlist.emptyCompletedTitle, Strings.Watchlist.emptyCompletedSubtitle, "checkmark.seal")
        }
    }
}
