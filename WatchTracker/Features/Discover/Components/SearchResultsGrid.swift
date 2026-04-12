import SwiftUI

struct SearchResultsGrid: View {
    let results: [MediaDetail]
    let isLoading: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 200)
            } else if !results.isEmpty {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(results) { item in
                        NavigationLink {
                            MediaDetailView(mediaType: item.mediaType, mediaId: item.id)
                        } label: {
                            PosterCardView(url: item.posterURL, title: item.displayTitle)
                        }
                        .buttonStyle(PressedButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
