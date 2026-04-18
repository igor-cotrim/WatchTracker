import SwiftUI

struct RankedMediaRowSection: View {
    let title: String
    let items: [MediaDetail]
    var seeAllViewModel: BrowseGridViewModel? = nil

    private var rankedItems: [MediaDetail] {
        Array(items.prefix(10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ScrollView(.horizontal) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(rankedItems.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            MediaDetailView(mediaType: item.mediaType, mediaId: item.id)
                        } label: {
                            TopTenCardView(
                                rank: index + 1,
                                posterURL: item.posterURL,
                                title: item.displayTitle
                            )
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
        if let seeAllViewModel {
            SectionHeaderView(
                title: title,
                seeAllTitle: Strings.Discover.seeAll
            ) {
                BrowseGridView(viewModel: seeAllViewModel)
                    .navigationTitle(title)
            }
        } else {
            SectionHeaderView(title: title)
        }
    }
}
