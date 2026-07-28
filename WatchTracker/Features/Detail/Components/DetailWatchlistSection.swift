import SwiftUI

struct DetailWatchlistSection: View {
    let viewModel: MediaDetailViewModel
    let mediaType: MediaType

    @State private var softFeedbackTrigger = 0
    @State private var mediumFeedbackTrigger = 0

    var body: some View {
        HStack(spacing: 12) {
            if viewModel.isCheckingStatus {
                loadingButton
            } else {
                watchlistMenu
            }

            if mediaType == .movie, !viewModel.isCheckingStatus {
                watchedButton
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: softFeedbackTrigger)
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: mediumFeedbackTrigger)
    }

    // MARK: - Subviews

    private var loadingButton: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .clipShape(.rect(cornerRadius: 10))
    }

    private var watchlistMenu: some View {
        Menu {
            ForEach(WatchlistStatus.allCases, id: \.self) { status in
                Button {
                    softFeedbackTrigger += 1
                    Task { await viewModel.addToWatchlist(status: status) }
                } label: {
                    Label(status.displayName, systemImage: status.icon)
                }
            }

            if viewModel.isOnWatchlist {
                Divider()

                Button(role: .destructive) {
                    mediumFeedbackTrigger += 1
                    Task { await viewModel.removeFromWatchlist() }
                } label: {
                    Label(Strings.Detail.watchlistRemove, systemImage: "trash")
                }
            }
        } label: {
            Label(
                viewModel.isOnWatchlist ? viewModel.displayStatus : Strings.Detail.watchlistAdd,
                systemImage: viewModel.isOnWatchlist ? "checkmark.circle.fill" : "plus.circle.fill"
            )
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                (viewModel.isOnWatchlist ? Color.brandPrimary : Color.brandAccent)
                    .opacity(0.15)
            )
            .foregroundStyle(viewModel.isOnWatchlist ? Color.brandPrimary : Color.brandAccent)
            .clipShape(.rect(cornerRadius: 10))
        }
        .accessibilityLabel(
            viewModel.isOnWatchlist
                ? Strings.Detail.watchlistAccessibilityOnList(viewModel.displayStatus)
                : Strings.Detail.watchlistAccessibilityAdd
        )
        .accessibilityHint(Strings.Detail.watchlistAccessibilityHint)
    }

    private var watchedButton: some View {
        let isWatched = viewModel.watchlistStatus == .completed
        return Button {
            softFeedbackTrigger += 1
            Task { await viewModel.addToWatchlist(status: .completed) }
        } label: {
            Label(
                Strings.Detail.watchlistWatched,
                systemImage: isWatched ? "eye.fill" : "eye"
            )
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                (isWatched ? Color.brandPrimary : Color(.systemGray5))
                    .opacity(isWatched ? 0.15 : 1)
            )
            .foregroundStyle(isWatched ? Color.brandPrimary : .secondary)
            .clipShape(.rect(cornerRadius: 10))
        }
    }
}
