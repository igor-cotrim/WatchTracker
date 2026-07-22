import SwiftUI

struct ProfileStatsGrid: View {
    let viewModel: ProfileViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var averageRatingValue: String {
        guard viewModel.averageRating > 0 else { return Strings.Profile.statsAverageRatingEmpty }
        return String(format: "%.1f", viewModel.averageRating / 2)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCard(
                icon: "tv",
                value: "\(viewModel.episodesWatched)",
                label: Strings.Profile.statsEpisodes,
                tint: .brandPrimary
            )
            StatCard(
                icon: "film",
                value: "\(viewModel.moviesWatched)",
                label: Strings.Profile.statsMovies,
                tint: .brandPrimary
            )
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.showsCompleted)",
                label: Strings.Profile.statsShowsCompleted,
                tint: .brandPrimary
            )
            StatCard(
                icon: "star.fill",
                value: averageRatingValue,
                label: Strings.Profile.statsAverageRating,
                tint: .brandAccent
            )
            StatCard(
                icon: "star.leadinghalf.filled",
                value: "\(viewModel.titlesRated)",
                label: Strings.Profile.statsTitlesRated,
                tint: .brandAccent
            )
        }
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)

            Text(verbatim: value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text(verbatim: label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ProfileStatsGridSkeleton: View {
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView()
                        .frame(width: 24, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    SkeletonView()
                        .frame(width: 60, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    SkeletonView()
                        .frame(width: 90, height: 12)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
