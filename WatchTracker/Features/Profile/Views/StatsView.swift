import SwiftUI

struct StatsView: View {
    let viewModel: ProfileViewModel

    var body: some View {
        ScrollView {
            if let errorMessage = viewModel.errorMessage, viewModel.stats == nil {
                ErrorStateView(message: errorMessage) {
                    await viewModel.fetchStats()
                }
            } else {
                ProfileStatsGrid(stats: viewModel.isLoading ? nil : viewModel.stats)
                    .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Strings.Profile.statsSection)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchStats()
        }
        .task {
            await viewModel.fetchStats()
        }
    }
}

#Preview {
    NavigationStack {
        StatsView(viewModel: AppContainer.preview.makeProfileViewModel())
    }
}
