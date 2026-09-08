import Testing
import Foundation
@testable import WatchTracker

/// The composition root is the one place concrete dependencies are named, so the thing
/// worth pinning down is that it actually assembles: every factory returns a view model
/// in its starting state, and the preview graph answers without a backend.
@MainActor
@Suite("AppContainer", .tags(.async), .timeLimit(.minutes(1)))
struct AppContainerTests {

    private let container = AppContainer.preview

    // MARK: - View model factories

    /// Asserts the starting *configuration*, not emptiness: `AppContainer.preview` is a
    /// shared graph, so its watchlist cache may already be warm from another test.
    @Test func `the watchlist view model starts on the watching tab`() {
        let viewModel = container.makeWatchlistViewModel()
        #expect(viewModel.selectedStatus == .watching)
        #expect(viewModel.selectedFilter == .all)
        #expect(viewModel.isLoading == false)
    }

    @Test func `the detail view model is built for one title`() {
        let viewModel = container.makeMediaDetailViewModel(type: .tv, id: 1396)
        #expect(viewModel.mediaType == .tv)
        #expect(viewModel.mediaId == 1396)
        guard case .idle = viewModel.state else {
            return #expect(Bool(false), "a freshly built detail view model is idle")
        }
    }

    @Test func `the browse view model starts with every row loading`() {
        let viewModel = container.makeDiscoverBrowseViewModel()
        #expect(viewModel.trending.isLoading)
        #expect(viewModel.selectedProvider == nil)
    }

    @Test func `the search view model starts empty`() {
        let viewModel = container.makeSearchViewModel()
        #expect(viewModel.query.isEmpty)
        #expect(viewModel.isSearching == false)
    }

    @Test(arguments: [BrowseFeed.trending, .nowPlaying, .popularMovies, .topRatedMovies, .upcoming])
    func `a browse grid is built for any feed`(feed: BrowseFeed) {
        #expect(container.makeBrowseGridViewModel(for: feed).items.isEmpty)
    }

    @Test func `the remaining factories assemble`() {
        #expect(container.makeContinueWatchingViewModel().items.isEmpty)
        #expect(container.makeUpcomingViewModel().items.isEmpty)
        #expect(container.makePersonViewModel().person == nil)
        #expect(container.makeExportViewModel().result == nil)
        #expect(container.makeImportViewModel().result == nil)
    }

    // MARK: - The preview graph

    /// Previews used to reach the live backend and the keychain, because the app target
    /// had no fakes at all. These are what stands in for them now.
    @Test func `the preview graph answers offline`() async {
        let watchlist = container.makeWatchlistViewModel()
        await watchlist.fetchWatchlist(forceRefresh: true)
        #expect(watchlist.allItems.isEmpty == false)

        let detail = container.makeMediaDetailViewModel(type: .movie, id: 550)
        await detail.load()
        #expect(detail.media != nil)

        let browse = container.makeDiscoverBrowseViewModel()
        await browse.load()
        #expect(browse.trending.items.isEmpty == false)
        #expect(browse.providers.isEmpty == false)

        let profile = container.makeProfileViewModel()
        await profile.fetchStats()
        #expect(profile.stats?.moviesWatched == PreviewLibrary.stats.moviesWatched)
    }

    @Test func `the preview auth service reports a signed-in user`() {
        #expect(container.auth.isAuthenticated)
        #expect(container.auth.currentUser == nil)
    }

    /// Every fixture is decoded from a JSON literal, so a typo in one is a trap rather
    /// than a compile error. Touching them all is what turns that into a test failure.
    @Test func `every preview fixture decodes`() {
        #expect(PreviewLibrary.movie.mediaType == .movie)
        #expect(PreviewLibrary.show.mediaType == .tv)
        #expect(PreviewLibrary.show.seasons?.isEmpty == false)
        #expect(PreviewLibrary.season.episodes?.isEmpty == false)
        #expect(PreviewLibrary.person.credits.isEmpty == false)
        #expect(PreviewLibrary.watchlist.count == 3)
        #expect(PreviewLibrary.continueWatching.first?.nextEpisode != nil)
        #expect(PreviewLibrary.upcoming.first?.nextEpisode.localDaysUntilAir != nil)
        #expect(PreviewLibrary.providers.count == 3)
        #expect(PreviewLibrary.catalogue.isEmpty == false)
        #expect(PreviewLibrary.genres.isEmpty == false)
        #expect(PreviewLibrary.stats.moviesWatched > 0)
    }
}
