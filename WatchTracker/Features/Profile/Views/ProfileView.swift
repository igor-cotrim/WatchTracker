import SwiftUI
import Auth

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                // User Info
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.brandPrimary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: authService.currentUser?.email ?? "")
                                .font(.headline)
                            Text(Strings.Profile.member)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Stats
                Section(Strings.Profile.stats) {
                    if viewModel.isLoading {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack {
                                SkeletonView()
                                    .frame(width: 120, height: 14)
                                    .clipShape(Capsule())
                                Spacer()
                                SkeletonView()
                                    .frame(width: 40, height: 14)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 2)
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(verbatim: errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        StatRow(title: Strings.Profile.statsEpisodes, value: "\(viewModel.episodesWatched)")
                        StatRow(title: Strings.Profile.statsMovies, value: "\(viewModel.moviesWatched)")
                        StatRow(title: Strings.Profile.statsWatchlist, value: "\(viewModel.moviesInWatchlist)")
                        StatRow(title: Strings.Profile.statsShows, value: "\(viewModel.showsTracking)")
                        StatRow(title: Strings.Profile.statsShowsCompleted, value: "\(viewModel.showsCompleted)")
                    }
                }

                // Actions
                Section {
                    Button(Strings.Profile.signOut, role: .destructive) {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                }
            }
            .navigationTitle(Strings.Profile.title)
            .task {
                await viewModel.fetchStats()
            }
        }
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(verbatim: title)
            Spacer()
            Text(verbatim: value)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
