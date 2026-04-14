import SwiftUI

struct ContinueWatchingSection: View {
    let viewModel: ContinueWatchingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: Strings.Home.continueWatching)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            MediaDetailView(mediaType: .tv, mediaId: item.tmdbId)
                        } label: {
                            ContinueWatchingCard(item: item) {
                                Task { await viewModel.markAsWatched(item) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ContinueWatchingCard: View {
    let item: ContinueWatchingItem
    let onMarkWatched: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: item.stillURL ?? item.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16 / 9, contentMode: .fill)
                    default:
                        Color(.systemGray5)
                            .aspectRatio(16 / 9, contentMode: .fill)
                    }
                }
                .frame(width: 280)
                .clipped()

                Button(action: onMarkWatched) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, Color.brandPrimary)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let next = item.nextEpisode {
                    Text(verbatim: next.displayLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 280)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
