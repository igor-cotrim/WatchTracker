import SwiftUI

struct DetailTitleSection: View {
    let media: MediaDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(media.displayTitle)
                .font(.title2.bold())

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.ratingStarFilled)
                    .font(.caption)
                    .accessibilityHidden(true)

                if let voteAverage = media.voteAverage {
                    Text(voteAverage, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline)
                } else {
                    Text("–")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("  |  ")
                    .foregroundStyle(.secondary)

                Text((media.releaseDateFormatted ?? "–"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("  |  ")
                    .foregroundStyle(.secondary)

                Text((media.genres?.map(\.name).joined(separator: ", ")) ?? "–")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let certification = media.certification, !certification.isEmpty {
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
        }
    }
}
