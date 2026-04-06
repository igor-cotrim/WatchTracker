import SwiftUI

struct WatchlistCardView: View {
    let item: WatchItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Poster
            AsyncImage(url: item.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                case .failure:
                    posterPlaceholder
                case .empty:
                    SkeletonView()
                        .aspectRatio(2/3, contentMode: .fill)
                @unknown default:
                    posterPlaceholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Title overlay
            VStack(alignment: .leading) {
                Spacer()
                Text(item.title ?? "Unknown")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // New episodes badge
            if let count = item.newEpisodesCount, count > 0 {
                Text("\(count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .aspectRatio(2/3, contentMode: .fill)
            .overlay {
                Image(systemName: "film")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}
