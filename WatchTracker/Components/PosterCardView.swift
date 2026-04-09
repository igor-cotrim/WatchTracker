import SwiftUI

struct PosterCardView: View {
    let url: URL?
    let title: String
    var width: CGFloat = 120

    /// Fixed height for the title area so cards in a row always align,
    /// regardless of whether the title fills one line or two.
    private var titleHeight: CGFloat { 36 }

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
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            Text(verbatim: title)
                .font(.caption)
                .lineLimit(2)
                .frame(width: width, height: titleHeight, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
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
    HStack {
        PosterCardView(url: nil, title: "Short Title")
        PosterCardView(url: nil, title: "A Very Long Movie Title That Wraps Two Lines")
    }
    .padding()
}
