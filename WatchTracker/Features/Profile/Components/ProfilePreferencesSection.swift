import SwiftUI

struct ProfilePreferencesSection: View {
    let viewModel: ProfileViewModel

    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system

    /// The per-app "Preferred Language" section is provided by iOS itself —
    /// it shows up because the app ships more than one localization.
    private let appSettingsURL = URL(string: UIApplication.openSettingsURLString)

    var body: some View {
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
            .tint(Color.secondary)

            if let appSettingsURL {
                Link(destination: appSettingsURL) {
                    SettingsLabel(
                        title: Strings.Profile.language,
                        systemImage: "globe",
                        tint: .teal,
                        value: Bundle.main.currentLanguageName,
                        isExternal: true
                    )
                }
            }

            Toggle(isOn: Binding(
                get: { viewModel.episodeRemindersEnabled },
                set: { enabled in Task { await viewModel.setEpisodeReminders(enabled) } }
            )) {
                SettingsLabel(
                    title: Strings.Notifications.episodeReminders,
                    systemImage: "bell.badge",
                    tint: .orange
                )
            }
        }
    }
}

#Preview {
    List {
        ProfilePreferencesSection(viewModel: ProfileViewModel(auth: AuthService()))
    }
}
