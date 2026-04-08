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
                Button {
                    onRate?(star * 2)
                } label: {
                    starImage(for: star)
                        .font(.body)
                        .foregroundStyle(starColor(for: star))
                }
                .buttonStyle(.plain)
                .disabled(onRate == nil)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(onRate != nil ? "Avaliação" : "Avaliação do usuário")
        .accessibilityValue(rating == 0 ? "Sem avaliação" : "\(rating) de \(maxRating)")
        .accessibilityAdjustableAction { direction in
            guard let onRate else { return }
            switch direction {
            case .increment: onRate(min(rating + 1, maxRating))
            case .decrement: onRate(max(rating - 1, 0))
            @unknown default: break
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
