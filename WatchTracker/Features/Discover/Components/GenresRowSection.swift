import SwiftUI

struct GenresRowSection: View {
    let genres: [Genre]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: Strings.Discover.genres)
                .font(.title3.bold())
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(genres) { genre in
                        NavigationLink {
                            GenreBrowseView(genre: genre)
                        } label: {
                            Text(verbatim: genre.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.brandPrimary.opacity(0.15))
                                .foregroundStyle(Color.brandPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PressedButtonStyle())
                        .accessibilityLabel(Strings.Discover.browseAccessibility(genre.name))
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}
