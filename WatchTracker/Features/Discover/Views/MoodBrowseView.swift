import SwiftUI

/// A mood preset opened as its own screen. The query it browses is `BrowseFeed.mood`,
/// so this is only the title around the shared grid.
struct MoodBrowseView: View {
    let mood: MoodPreset

    var body: some View {
        BrowseGridView(feed: .mood(mood))
            .navigationTitle(mood.title)
    }
}
