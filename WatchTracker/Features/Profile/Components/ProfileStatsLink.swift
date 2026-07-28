import SwiftUI

struct ProfileStatsLink: View {
    let stats: ProfileStats?

    var body: some View {
        VStack(spacing: 14) {
            SettingsLabel(
                title: Strings.Profile.statsLink,
                systemImage: "chart.bar.xaxis",
                tint: .brandPrimary
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                metric(value: stats?.episodesWatched.formatted(), label: Strings.Profile.statsShortEpisodes)
                separator
                metric(value: stats?.moviesWatched.formatted(), label: Strings.Profile.statsShortMovies)
                separator
                metric(value: stats?.averageRatingDisplay, label: Strings.Profile.statsAverageRating)
            }
        }
        .padding(.vertical, 6)
    }

    private var separator: some View {
        Divider().frame(height: 32)
    }

    private func metric(value: String?, label: String) -> some View {
        VStack(spacing: 1) {
            Group {
                if let value {
                    Text(verbatim: value)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                } else {
                    SkeletonView()
                        .frame(width: 42, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .frame(height: 28)

            Text(verbatim: label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(label): \(value ?? "")"))
    }
}

#Preview {
    List {
        Section {
            NavigationLink {
                EmptyView()
            } label: {
                ProfileStatsLink(
                    stats: ProfileStats(
                        episodesWatched: 318,
                        moviesWatched: 42,
                        showsCompleted: 12,
                        titlesRated: 57,
                        averageRating: 8.4
                    )
                )
            }
        }
        Section {
            NavigationLink {
                EmptyView()
            } label: {
                ProfileStatsLink(stats: nil)
            }
        }
    }
}
