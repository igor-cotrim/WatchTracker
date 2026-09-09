import SwiftUI

/// The grid behind an applied filter. Like `MoodBrowseView`, this is only the title around
/// the shared `BrowseGridView` — the query lives in `BrowseFeed.filtered`.
struct FilteredResultsView: View {
    let filter: DiscoverFilter

    var body: some View {
        BrowseGridView(feed: .filtered(filter))
            .navigationTitle(Strings.DiscoverFilter.resultsTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FilteredResultsView(filter: DiscoverFilter())
    }
    .environment(AppContainer.preview)
}
