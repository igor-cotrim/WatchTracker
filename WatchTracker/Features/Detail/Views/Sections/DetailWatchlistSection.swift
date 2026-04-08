import SwiftUI

struct DetailWatchlistSection: View {
    let viewModel: MediaDetailViewModel
    let mediaType: MediaType

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(WatchlistStatus.allCases, id: \.self) { status in
                    Button {
                        Task { await viewModel.addToWatchlist(status: status) }
                    } label: {
                        Label(status.displayName, systemImage: status.icon)
                    }
                }

                if viewModel.isOnWatchlist {
                    Divider()

                    Button(role: .destructive) {
                        Task { await viewModel.removeFromWatchlist() }
                    } label: {
                        Label("Remover da Lista", systemImage: "trash")
                    }
                }
            } label: {
                Label(
                    viewModel.isOnWatchlist ? viewModel.displayStatus : "Adicionar",
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
            .accessibilityLabel(viewModel.isOnWatchlist ? "Na lista: \(viewModel.displayStatus)" : "Adicionar à lista")
            .accessibilityHint("Toque para alterar status na lista")

            if mediaType == .movie {
                Button {
                    Task { await viewModel.addToWatchlist(status: .completed) }
                } label: {
                    Label(
                        "Assistido",
                        systemImage: viewModel.watchlistStatus == .completed ? "eye.fill" : "eye"
                    )
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        (viewModel.watchlistStatus == .completed ? Color.brandPrimary : Color(.systemGray5))
                            .opacity(viewModel.watchlistStatus == .completed ? 0.15 : 1)
                    )
                    .foregroundStyle(viewModel.watchlistStatus == .completed ? Color.brandPrimary : .secondary)
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
    }
}
