import SwiftUI

struct HomeView: View {
    @State private var viewModel = WatchlistViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(MediaFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                WatchlistView(viewModel: viewModel)
            }
            .navigationTitle("Acompanhando")
            .task {
                await viewModel.fetchWatchlist()
            }
        }
    }
}

#Preview {
    HomeView()
}
