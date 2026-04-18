import SwiftUI

struct TopTenCardView: View {
    let rank: Int
    let posterURL: URL?
    let title: String

    private let posterWidth: CGFloat = 110

    var body: some View {
        HStack(alignment: .bottom, spacing: -18) {
            rankNumeral

            Group {
                if let posterURL = posterURL {
                    AsyncImage(url: posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(2 / 3, contentMode: .fill)
                        case .failure:
                            posterPlaceholder
                        case .empty:
                            SkeletonView().aspectRatio(2 / 3, contentMode: .fill)
                        @unknown default:
                            posterPlaceholder
                        }
                    }
                } else {
                    posterPlaceholder
                }
            }
            .frame(width: posterWidth, height: posterWidth * 1.5)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Discover.topTenRank(rank, title: title))
        .accessibilityAddTraits(.isButton)
    }

    private var rankNumeral: some View {
        Text(verbatim: "\(rank)")
            .font(.system(size: 150, weight: .black, design: .rounded))
            .italic()
            .foregroundStyle(Color.brandPrimary.opacity(0.85))
            .lineLimit(1)
            .fixedSize()
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
    ScrollView(.horizontal) {
        HStack(spacing: 8) {
            ForEach(1...10, id: \.self) { rank in
                TopTenCardView(rank: rank, posterURL: nil, title: "Sample title \(rank)")
            }
        }
        .padding()
    }
}
