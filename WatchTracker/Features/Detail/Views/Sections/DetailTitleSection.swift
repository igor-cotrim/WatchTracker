import SwiftUI

struct DetailTitleSection: View {
    let media: MediaDetail
    let userRating: Int?
    let onRate: (Int) -> Void

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

                Text((media.genres?.map(\.name).joined(separator: ", ")) ?? "–")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let rating = userRating {
                Text("Your rating: \(rating)/10")
                    .font(.caption)
                    .foregroundStyle(Color.brandAccent)
            }

            RatingStarsView(rating: userRating ?? 0, maxRating: 10, onRate: onRate)
        }
    }
}
