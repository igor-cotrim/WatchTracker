import SwiftUI
import Testing
@testable import WatchTracker

/// Renders `Features/Discover/Components/`, all previously at 0%.
///
/// `SearchFilterBar` builds its year list from `Date()`; that is fine to *render* (the
/// list is never empty), it just cannot be snapshotted, since the options would change
/// every January.
@MainActor
@Suite("Discover components render", .tags(.view, .pure))
struct DiscoverComponentRenderTests {

    private func media(_ count: Int) -> [MediaDetail] {
        (1...max(count, 1)).prefix(count).map {
            TestFixtures.mediaDetail(id: $0, title: "Title \($0)", posterPath: nil, backdropPath: nil)
        }
    }

    @Test func `mood strip renders`() {
        _ = render(MoodStripView(), height: 140)
    }

    @Test(arguments: [nil, 8])
    func `provider strip renders with and without a selection`(selected: Int?) {
        let providers = [
            TestFixtures.streamingProvider(providerId: 8, providerName: "Netflix"),
            TestFixtures.streamingProvider(providerId: 9, providerName: "Prime")
        ]
        _ = render(
            ProviderStripView(providers: providers, selectedProviderId: selected, onSelect: { _ in }),
            height: 100
        )
    }

    @Test func `provider strip renders with no providers`() {
        _ = render(ProviderStripView(providers: [], selectedProviderId: nil, onSelect: { _ in }), height: 100)
    }

    @Test(arguments: [0, 3, 10])
    func `ranked row renders any number of items`(count: Int) {
        _ = render(RankedMediaRowSection(title: "Top 10", items: media(count)), height: 320)
    }

    @Test func `top ten card renders low and high ranks`() {
        for rank in [1, 10] {
            rasterize(TopTenCardView(rank: rank, posterURL: nil, title: "Title"), width: 200, height: 240)
        }
    }

    @Test func `search filter bar renders`() {
        _ = render(
            SearchFilterBar(selectedType: .constant(nil), selectedYear: .constant(nil)),
            height: 80
        )
    }

    @Test func `search filter bar renders with both filters applied`() {
        _ = render(
            SearchFilterBar(selectedType: .constant(.movie), selectedYear: .constant(2024)),
            height: 80
        )
    }

    @Test(arguments: [[], ["fight club", "dune"]])
    func `search history renders empty and populated`(history: [String]) {
        _ = render(
            SearchHistoryList(history: history, onSelect: { _ in }, onRemove: { _ in }, onClear: {}),
            height: 300
        )
    }

    @Test(arguments: [true, false])
    func `search results grid renders loading and loaded`(isLoading: Bool) {
        _ = render(SearchResultsGrid(results: media(6), isLoading: isLoading), height: 600)
    }

    /// An empty result set is what a search with no matches produces.
    @Test func `search results grid renders no results`() {
        _ = render(SearchResultsGrid(results: [], isLoading: false), height: 600)
    }

    @Test func `search suggestion row renders`() {
        _ = render(SearchSuggestionRow(item: media(1)[0]), height: 80)
    }

    @Test(arguments: [0, 5])
    func `search suggestions list renders`(count: Int) {
        _ = render(SearchSuggestionsList(suggestions: media(count)), height: 400)
    }
}
