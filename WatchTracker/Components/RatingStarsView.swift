import SwiftUI

struct RatingStarsView: View {
    let rating: Int
    let maxRating: Int
    let onRate: ((Int) -> Void)?

    /// Creates a star rating view.
    /// - Parameters:
    ///   - rating: Current rating value (e.g. 7 out of 10).
    ///   - maxRating: Maximum rating (default 10). Stars shown = maxRating / 2 (half-star system).
    ///   - onRate: Callback when user taps a star. Pass nil for read-only.
    init(rating: Int, maxRating: Int = 10, onRate: ((Int) -> Void)? = nil) {
        self.rating = rating
        self.maxRating = maxRating
        self.onRate = onRate
    }

    private var starCount: Int { maxRating / 2 }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...starCount, id: \.self) { star in
                starImage(for: star)
                    .font(.body)
                    .foregroundStyle(starColor(for: star))
                    .onTapGesture {
                        onRate?(star * 2) // Convert star index to rating value
                    }
            }
        }
    }

    private func starImage(for star: Int) -> Image {
        let ratingInStars = rating / 2
        let hasHalf = rating % 2 == 1

        if star <= ratingInStars {
            return Image(systemName: "star.fill")
        } else if star == ratingInStars + 1 && hasHalf {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }

    private func starColor(for star: Int) -> Color {
        let ratingInStars = rating / 2
        let hasHalf = rating % 2 == 1
        let isFilled = star <= ratingInStars || (star == ratingInStars + 1 && hasHalf)
        return isFilled ? Color.ratingStarFilled : Color.ratingStarEmpty
    }
}

#Preview {
    VStack(spacing: 16) {
        RatingStarsView(rating: 7, maxRating: 10)
        RatingStarsView(rating: 4, maxRating: 10)
        RatingStarsView(rating: 10, maxRating: 10)
    }
}
