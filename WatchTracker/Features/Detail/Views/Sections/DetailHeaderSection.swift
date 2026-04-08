import SwiftUI

struct DetailHeaderSection: View {
    let media: MediaDetail

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: media.backdropURL) { image in
                image.resizable().aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                SkeletonView()
                    .aspectRatio(16/9, contentMode: .fill)
            }
            .clipped()

            AsyncImage(url: media.posterURL) { image in
                image.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                SkeletonView()
                    .clipShape(.rect(cornerRadius: 8))
            }
            .frame(width: 100, height: 150)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(radius: 4)
            .padding(.leading)
            .offset(y: 40)
        }
        .padding(.bottom, 40)
    }
}
