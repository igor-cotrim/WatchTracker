import SwiftUI

struct DetailTitleSection: View {
    let media: MediaDetail

    private var genreList: String? {
        guard let names = media.genres?.map(\.name), !names.isEmpty else { return nil }
        return names.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(media.displayTitle)
                .font(.title2.bold())

            // Two rows on purpose. The short numeric facts share a line — they have a
            // predictable width — while the genres, the one segment whose length depends
            // on the title, get the full width to themselves. Cramming all of it into a
            // single row truncated both the date and the genres.
            factsRow
            genresRow
        }
    }

    private var factsRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.ratingStarFilled)
                    .font(.caption)
                    .accessibilityHidden(true)

                // Unlike the other facts this keeps its en-dash fallback: dropping it
                // would leave the star icon dangling on its own.
                if let voteAverage = media.voteAverage {
                    Text(voteAverage, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline)
                } else {
                    Text(verbatim: "–")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let releaseDate = media.releaseDateFormatted {
                separator
                fact(releaseDate)
            }

            if let minutes = media.runtimeMinutes {
                separator
                fact(Strings.Detail.runtime(minutes: minutes, perEpisode: media.mediaType == .tv))
            }

            if let certification = media.certification, !certification.isEmpty {
                separator
                Text(verbatim: certification)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
            }

            Spacer(minLength: 0)
        }
        // Read as one phrase instead of stuttering through each separator.
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var genresRow: some View {
        if let genreList {
            Text(verbatim: genreList)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func fact(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var separator: some View {
        Text(verbatim: "|")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}
