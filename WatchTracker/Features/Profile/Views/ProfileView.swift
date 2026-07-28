import SwiftUI
import MessageUI
import Auth

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.openURL) private var openURL

    @State private var viewModel = ProfileViewModel()
    @AppStorage("episodeRemindersEnabled") private var episodeRemindersEnabled = false
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var isShowingMailComposer = false
    @State private var showMailUnavailable = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileAccountCard(user: authService.currentUser)
                }

                Section(Strings.Profile.statsSection) {
                    NavigationLink {
                        StatsView(viewModel: viewModel)
                    } label: {
                        ProfileStatsLink(stats: viewModel.stats)
                    }
                }

                Section(Strings.Profile.preferencesSection) {
                    Picker(selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Label {
                                Text(verbatim: option.title)
                            } icon: {
                                Image(systemName: option.icon)
                            }
                            .tag(option)
                        }
                    } label: {
                        SettingsLabel(
                            title: Strings.Profile.appearance,
                            systemImage: "circle.lefthalf.filled",
                            tint: .indigo
                        )
                    }
                    .pickerStyle(.menu)

                    Button {
                        openAppSettings()
                    } label: {
                        SettingsLabel(
                            title: Strings.Profile.language,
                            systemImage: "globe",
                            tint: .teal,
                            value: Bundle.main.currentLanguageName,
                            isExternal: true
                        )
                    }

                    Toggle(isOn: $episodeRemindersEnabled) {
                        SettingsLabel(
                            title: Strings.Notifications.episodeReminders,
                            systemImage: "bell.badge",
                            tint: .orange
                        )
                    }
                    .onChange(of: episodeRemindersEnabled) { _, enabled in
                        Task { await updateEpisodeReminders(enabled: enabled) }
                    }
                }

                Section(Strings.Profile.dataSection) {
                    NavigationLink {
                        ImportView()
                    } label: {
                        SettingsLabel(
                            title: Strings.Import.title,
                            systemImage: "square.and.arrow.down",
                            tint: .blue
                        )
                    }
                }

                Section(Strings.Profile.supportSection) {
                    Button {
                        presentFeedback()
                    } label: {
                        SettingsLabel(
                            title: Strings.Profile.feedback,
                            systemImage: "envelope",
                            tint: .brandPrimary
                        )
                    }

                    Link(destination: Config.reviewURL) {
                        SettingsLabel(
                            title: Strings.Profile.rateApp,
                            systemImage: "star",
                            tint: .brandAccent,
                            isExternal: true
                        )
                    }
                }

                Section {
                    Link(destination: Config.tmdbURL) {
                        SettingsLabel(
                            title: Strings.Profile.tmdb,
                            systemImage: "film",
                            tint: .tmdbBrand,
                            isExternal: true
                        )
                    }

                    Link(destination: Config.privacyPolicyURL) {
                        SettingsLabel(
                            title: Strings.Profile.privacyPolicy,
                            systemImage: "lock",
                            tint: Color(.systemGray),
                            isExternal: true
                        )
                    }
                } header: {
                    Text(Strings.Profile.aboutSection)
                } footer: {
                    Text(Strings.Profile.tmdbAttribution)
                }

                Section {
                    Button(Strings.Profile.signOut, role: .destructive) {
                        Task { try? await authService.signOut() }
                    }

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
                    Text(Strings.Profile.accountSection)
                } footer: {
                    Text(Strings.Profile.dangerZoneFooter)
                }
            }
            .navigationTitle(Strings.Profile.title)
            .alert(Strings.Profile.deleteAccountConfirmTitle, isPresented: $showDeleteConfirm) {
                Button(Strings.Common.cancel, role: .cancel) { }
                Button(Strings.Profile.deleteAccountConfirmButton, role: .destructive) {
                    Task { await deleteAccount() }
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
            .alert(Strings.Feedback.errorTitle, isPresented: $showMailUnavailable) {
                Button(Strings.Common.ok, role: .cancel) { }
            } message: {
                Text(verbatim: Strings.Feedback.errorMessage(email: Config.supportEmail))
            }
            .sheet(isPresented: $isShowingMailComposer) {
                MailComposeView(
                    recipient: FeedbackComposer.recipient,
                    subject: FeedbackComposer.subject,
                    body: FeedbackComposer.body(accountEmail: authService.currentUser?.email)
                )
                .ignoresSafeArea()
            }
            .task {
                await viewModel.fetchStats()
            }
        }
    }

    // MARK: - Actions

    private func updateEpisodeReminders(enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.shared.requestAuthorization()
            if !granted { episodeRemindersEnabled = false }
        } else {
            await NotificationService.shared.cancelAllEpisodeNotifications()
        }
    }

    /// The per-app "Preferred Language" section is provided by iOS itself —
    /// it shows up because the app ships more than one localization.
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func presentFeedback() {
        if MFMailComposeViewController.canSendMail() {
            isShowingMailComposer = true
            return
        }

        guard let url = FeedbackComposer.mailtoURL(accountEmail: authService.currentUser?.email) else {
            showMailUnavailable = true
            return
        }

        openURL(url) { accepted in
            if !accepted { showMailUnavailable = true }
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        do {
            try await authService.deleteAccount()
        } catch {
            deleteError = error.userFacingMessage
        }
        isDeleting = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
