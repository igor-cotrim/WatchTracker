import SwiftUI

struct ProfileAboutSection: View {
    var body: some View {
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
    }
}

#Preview {
    List {
        ProfileAboutSection()
    }
}
