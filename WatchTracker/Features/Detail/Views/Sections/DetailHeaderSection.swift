import SwiftUI

struct DetailHeaderSection: View {
    let media: MediaDetail

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop image
            AsyncImage(url: media.backdropURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                default:
                    backdropPlaceholder
                }
            }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color(.systemBackground)],
                    startPoint: .init(x: 0.5, y: 0.25),
                    endPoint: .bottom
                )
                .frame(height: 100)
            }

            // Poster overlapping the backdrop
            AsyncImage(url: media.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(2/3, contentMode: .fill)
                default:
                    posterPlaceholder
                }
            }
            .frame(width: 100, height: 150)
            .clipShape(.rect(cornerRadius: 10))
            .shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 8)
            .padding(.leading)
            .offset(y: 40)
        }
        .padding(.bottom, 40)
    }

    private var backdropPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .aspectRatio(16/9, contentMode: .fill)
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(Color(.systemGray3))
            }
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .aspectRatio(2/3, contentMode: .fill)
            .overlay {
                Image(systemName: "film")
                    .font(.title2)
                    .foregroundStyle(Color(.systemGray3))
            }
    }
}
