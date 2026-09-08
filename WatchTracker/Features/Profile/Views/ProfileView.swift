import SwiftUI

struct ProfileView: View {
    private let container: AppContainer
    @State private var viewModel: ProfileViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(wrappedValue: container.makeProfileViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileAccountCard(user: viewModel.currentUser)
                }

                Section(Strings.Profile.statsSection) {
                    NavigationLink {
                        StatsView(viewModel: viewModel)
                    } label: {
                        ProfileStatsLink(stats: viewModel.stats)
                    }
                }

                ProfilePreferencesSection(viewModel: viewModel)

                Section(Strings.Profile.dataSection) {
                    NavigationLink {
                        DataView(container: container)
                    } label: {
                        SettingsLabel(
                            title: Strings.Data.title,
                            systemImage: "arrow.up.arrow.down.square",
                            tint: .blue
                        )
                    }
                }

                ProfileSupportSection(viewModel: viewModel)

                ProfileAboutSection()

                ProfileAccountSection(viewModel: viewModel)
            }
            .navigationTitle(Strings.Profile.title)
            .task {
                await viewModel.fetchStats()
            }
        }
    }
}

#Preview {
    ProfileView(container: .preview)
        .environment(AppContainer.preview)
}
