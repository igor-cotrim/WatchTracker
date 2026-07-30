import SwiftUI

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    init(auth: any AuthServiceProtocol) {
        _viewModel = State(wrappedValue: ProfileViewModel(auth: auth))
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
                        DataView()
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
    ProfileView(auth: AuthService())
}
