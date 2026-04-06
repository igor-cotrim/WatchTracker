import SwiftUI

struct PosterCardView: View {
    let url: URL?
    let title: String
    var width: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: url) { phase in
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
            .frame(width: width, height: width * 1.5)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            Text(title)
                .font(.caption)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "film")
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    PosterCardView(url: nil, title: "Movie Title")
}
