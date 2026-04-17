import SwiftUI

struct HomeView: View {
    @State private var viewModel = WatchlistViewModel(
        service: WatchlistService(),
        store: .shared
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StatusFilterBar(viewModel: viewModel)
                MediaFilterTabBar(selected: $viewModel.selectedFilter)

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
        }
    }
}

#Preview {
    HomeView()
}
