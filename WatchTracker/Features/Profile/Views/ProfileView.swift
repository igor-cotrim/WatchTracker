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
                    Group {
                        if viewModel.isLoading {
                            ProfileStatsGridSkeleton()
                        } else if let errorMessage = viewModel.errorMessage {
                            Text(verbatim: errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else {
                            ProfileStatsGrid(viewModel: viewModel)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
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

                // Import
                Section(Strings.Import.sectionTitle) {
                    NavigationLink {
                        ImportView()
                    } label: {
                        Label(Strings.Import.title, systemImage: "square.and.arrow.down")
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

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
