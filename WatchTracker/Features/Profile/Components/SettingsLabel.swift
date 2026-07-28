import SwiftUI

struct SettingsIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(tint.opacity(0.16))
            .frame(width: 29, height: 29)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
            }
    }
}

struct SettingsLabel: View {
    let title: String
    let systemImage: String
    let tint: Color
    var value: String? = nil
    var isExternal = false

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemImage: systemImage, tint: tint)

            Text(verbatim: title)
                .foregroundStyle(.primary)

            if value != nil || isExternal {
                Spacer(minLength: 8)
            }

            if let value {
                Text(verbatim: value)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if isExternal {
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    List {
        Section {
            NavigationLink {
                EmptyView()
            } label: {
                SettingsLabel(
                    title: Strings.Profile.statsLink,
                    systemImage: "chart.bar.xaxis",
                    tint: .brandPrimary
                )
            }

            Toggle(isOn: .constant(true)) {
                SettingsLabel(
                    title: Strings.Notifications.episodeReminders,
                    systemImage: "bell.badge",
                    tint: .orange
                )
            }

            Link(destination: Config.tmdbURL) {
                SettingsLabel(
                    title: Strings.Profile.tmdb,
                    systemImage: "film",
                    tint: .tmdbBrand,
                    isExternal: true
                )
            }
        }
    }
}
