import SwiftUI

struct ProfileStatsGrid: View {
    let stats: ProfileStats?

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                cell(.episodes)
                cell(.movies)
            }
            GridRow {
                cell(.showsCompleted)
                cell(.averageRating)
            }
            GridRow {
                cell(.titlesRated)
                    .gridCellColumns(2)
            }
        }
    }

    private func cell(_ metric: StatMetric) -> some View {
        StatCard(metric: metric, value: stats.map(metric.value))
    }
}

// MARK: - Metrics

private enum StatMetric {
    case episodes, movies, showsCompleted, averageRating, titlesRated

    var icon: String {
        switch self {
        case .episodes: "tv"
        case .movies: "film"
        case .showsCompleted: "checkmark.circle.fill"
        case .averageRating: "star.fill"
        case .titlesRated: "star.leadinghalf.filled"
        }
    }

    var label: String {
        switch self {
        case .episodes: Strings.Profile.statsEpisodes
        case .movies: Strings.Profile.statsMovies
        case .showsCompleted: Strings.Profile.statsShowsCompleted
        case .averageRating: Strings.Profile.statsAverageRating
        case .titlesRated: Strings.Profile.statsTitlesRated
        }
    }

    var tint: Color {
        switch self {
        case .episodes, .movies, .showsCompleted: .brandPrimary
        case .averageRating, .titlesRated: .brandAccent
        }
    }

    func value(from stats: ProfileStats) -> String {
        switch self {
        case .episodes: stats.episodesWatched.formatted()
        case .movies: stats.moviesWatched.formatted()
        case .showsCompleted: stats.showsCompleted.formatted()
        case .titlesRated: stats.titlesRated.formatted()
        case .averageRating: stats.averageRatingDisplay
        }
    }
}

// MARK: - Card

private struct StatCard: View {
    let metric: StatMetric
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: metric.icon)
                .font(.headline)
                .foregroundStyle(metric.tint)

            if let value {
                Text(verbatim: value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            } else {
                SkeletonView()
                    .frame(width: 60, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Text(verbatim: metric.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(metric.label): \(value ?? "")"))
    }
}

#Preview("Loaded") {
    ProfileStatsGrid(
        stats: ProfileStats(
            episodesWatched: 318,
            moviesWatched: 42,
            showsCompleted: 12,
            titlesRated: 57,
            averageRating: 8.4
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Loading") {
    ProfileStatsGrid(stats: nil)
        .padding()
        .background(Color(.systemGroupedBackground))
}
