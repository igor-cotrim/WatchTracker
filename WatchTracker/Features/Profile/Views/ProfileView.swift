import SwiftUI
import Auth

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var viewModel = ProfileViewModel()
    @AppStorage("episodeRemindersEnabled") private var episodeRemindersEnabled = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

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

                // Notifications
                Section(Strings.Notifications.sectionTitle) {
                    Toggle(Strings.Notifications.episodeReminders, isOn: $episodeRemindersEnabled)
                        .onChange(of: episodeRemindersEnabled) { _, enabled in
                            Task {
                                if enabled {
                                    let granted = await NotificationService.shared.requestAuthorization()
                                    if !granted { episodeRemindersEnabled = false }
                                } else {
                                    await NotificationService.shared.cancelAllEpisodeNotifications()
                                }
                            }
                        }
                }

                // About
                Section(Strings.Profile.aboutSection) {
                    Link(destination: URL(string: "https://www.themoviedb.org")!) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image("tmdb-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 14)
                                    .accessibilityLabel(Text(verbatim: "TMDB"))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(Strings.Profile.tmdbAttribution)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                    }

                    Link(destination: URL(string: "https://spice-swift-6a1.notion.site/WatchTracker-Privacy-Policy-38f36fb13fb58025a339c5d18152725c")!) {
                        HStack {
                            Text(Strings.Profile.privacyPolicy)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Sign out
                Section {
                    Button(Strings.Profile.signOut, role: .destructive) {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Text(Strings.Profile.deleteAccount)
                            if isDeleting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isDeleting)
                } header: {
                    Text(Strings.Profile.dangerZoneSection)
                        .foregroundStyle(.red)
                } footer: {
                    Text(Strings.Profile.dangerZoneFooter)
                }
            }
            .navigationTitle(Strings.Profile.title)
            .alert(Strings.Profile.deleteAccountConfirmTitle, isPresented: $showDeleteConfirm) {
                Button(Strings.Common.cancel, role: .cancel) { }
                Button(Strings.Profile.deleteAccountConfirmButton, role: .destructive) {
                    Task {
                        isDeleting = true
                        do {
                            try await authService.deleteAccount()
                        } catch {
                            deleteError = error.localizedDescription
                        }
                        isDeleting = false
                    }
                }
            } message: {
                Text(Strings.Profile.deleteAccountConfirmMessage)
            }
            .alert(
                Strings.Profile.deleteAccountErrorTitle,
                isPresented: Binding(
                    get: { deleteError != nil },
                    set: { if !$0 { deleteError = nil } }
                )
            ) {
                Button(Strings.Common.ok, role: .cancel) { deleteError = nil }
            } message: {
                Text(verbatim: deleteError ?? "")
            }
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
