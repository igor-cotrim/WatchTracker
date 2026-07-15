import SwiftUI

struct DetailRatingSection: View {
    let viewModel: MediaDetailViewModel
    let mediaType: MediaType

    @State private var feedbackTrigger = 0

    private var starValue: Double {
        viewModel.userRating.map { Double($0) / 2 } ?? 0
    }

    private var isCompleted: Bool {
        viewModel.watchlistStatus == .completed
    }

    private var isStarted: Bool {
        viewModel.watchlistStatus == .watching || viewModel.watchlistStatus == .completed
    }

    private var isLocked: Bool {
        mediaType == .tv && !isStarted && viewModel.userRating == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Rating.yourRating)
                .font(.headline)

            if isLocked {
                lockedControl
            } else {
                interactiveControl
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.userRating)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.watchlistStatus)
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }

    // MARK: - Interactive (movie always; series once completed)

    private var interactiveControl: some View {
        HStack(spacing: 14) {
            RatingStarsView(value: starValue, size: 32) { rating in
                feedbackTrigger += 1
                Task { await rate(rating) }
            }

            caption
        }
    }

    private func rate(_ rating: Int) async {
        if mediaType == .movie && !isCompleted {
            await viewModel.addToWatchlist(status: .completed)
        }
        await viewModel.rateMedia(rating: rating)
    }

    @ViewBuilder
    private var caption: some View {
        if let rating = viewModel.userRating {
            Text(verbatim: Strings.Rating.mood(forRating: rating))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.brandAccent)
                .id(rating)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.6).combined(with: .opacity),
                    removal: .opacity
                ))
        } else {
            Text(Strings.Rating.tapToRate)
                .font(.caption)
                .foregroundStyle(.secondary)
                .transition(.opacity)
        }
    }

    // MARK: - Locked (series not finished yet)

    private var lockedControl: some View {
        HStack(spacing: 14) {
            RatingStarsView(
                value: 0,
                size: 32,
                filledColor: .ratingStarEmpty,
                emptyColor: .ratingStarEmpty
            )
            .opacity(0.45)

            Label(Strings.Rating.startSeries, systemImage: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
