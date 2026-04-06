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
                            Text(authService.currentUser?.email ?? "User")
                                .font(.headline)
                            Text("Member")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Stats
                Section("Stats") {
                    StatRow(title: "Episodes Watched", value: "\(viewModel.episodesWatched)")
                    StatRow(title: "Movies Watched", value: "\(viewModel.moviesWatched)")
                    StatRow(title: "Shows Tracking", value: "\(viewModel.showsTracking)")
                    StatRow(title: "Total Hours", value: String(format: "%.0f h", viewModel.totalHours))
                }

                // Actions
                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
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
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
