import SwiftUI

struct MediaRowSection: View {
    let title: String
    let items: [MediaDetail]
    var seeAllFeed: BrowseFeed? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(items, id: \.identity) { item in
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
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let seeAllFeed {
            SectionHeaderView(
                title: title,
                seeAllTitle: Strings.Discover.seeAll
            ) {
                BrowseGridView(feed: seeAllFeed)
                    .navigationTitle(title)
            }
        } else {
            SectionHeaderView(title: title)
        }
    }
}
