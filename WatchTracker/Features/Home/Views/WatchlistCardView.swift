import SwiftUI

struct WatchlistCardView: View {
    let item: WatchItem
    @State private var badgeVisible = false

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
            .clipShape(.rect(cornerRadius: 10))

            // Title overlay
            VStack(alignment: .leading) {
                Spacer()
                Text(verbatim: item.title ?? Strings.Card.unknownTitle)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .clipShape(.rect(cornerRadius: 10))

            // New episodes badge with spring entrance
            if let count = item.newEpisodesCount, count > 0 {
                Text(verbatim: "\(count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .scaleEffect(badgeVisible ? 1.0 : 0.4)
                    .opacity(badgeVisible ? 1.0 : 0.0)
                    .onAppear {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.1)) {
                            badgeVisible = true
                        }
                    }
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel({
            var label = item.title ?? Strings.Card.unknownTitle
            if let count = item.newEpisodesCount, count > 0 {
                label += ", " + Strings.Card.newEpisodes(count)
            }
            return label
        }())
        .accessibilityHint(Strings.Card.accessibilityHint)
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray5))
            .aspectRatio(2/3, contentMode: .fill)
            .overlay {
                Image(systemName: "film")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}
