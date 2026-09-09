import SwiftUI

struct HomeView: View {
    @State private var viewModel: WatchlistViewModel
    @Environment(AppContainer.self) private var container

    init(container: AppContainer) {
        _viewModel = State(wrappedValue: container.makeWatchlistViewModel())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    StatusFilterBar(viewModel: viewModel)
                    MediaFilterTabBar(selected: $viewModel.selectedFilter)
                }

                TabView(selection: $viewModel.selectedFilter) {
                    ForEach(MediaFilter.allCases) { filter in
                        WatchlistView(viewModel: viewModel, filter: filter)
                            .tag(filter)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(Strings.Home.title)
            .task {
                await viewModel.fetchWatchlist()
            }
            .onAppear {
                viewModel.syncFromCache()
            }
            // Coming back into signal is the moment the user expects the list to be right,
            // not the next time they remember to pull down on it. `onChange` rather than
            // `task(id:)` so the initial value does not fire a second launch fetch.
            .onChange(of: container.network.isOnline) { _, isOnline in
                guard isOnline else { return }
                Task { await viewModel.fetchWatchlist(forceRefresh: true) }
            }
        }
    }
}

#Preview {
    HomeView(container: .preview)
        .environment(AppContainer.preview)
}
