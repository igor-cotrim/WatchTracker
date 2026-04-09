import SwiftUI

struct DetailHeaderSection: View {
    let media: MediaDetail

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop image
            AsyncImage(url: media.backdropURL) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                SkeletonView()
                    .aspectRatio(16/9, contentMode: .fill)
            }
            .clipped()
            .overlay(alignment: .bottom) {
                // Fade into the page background for a seamless transition
                LinearGradient(
                    colors: [.clear, Color(.systemBackground)],
                    startPoint: .init(x: 0.5, y: 0.25),
                    endPoint: .bottom
                )
                .frame(height: 100)
            }

            // Poster overlapping the backdrop
            AsyncImage(url: media.posterURL) { image in
                image.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                SkeletonView()
                    .clipShape(.rect(cornerRadius: 10))
            }
            .frame(width: 100, height: 150)
            .clipShape(.rect(cornerRadius: 10))
            .shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 8)
            .padding(.leading)
            .offset(y: 40)
        }
        .padding(.bottom, 40)
    }
}
