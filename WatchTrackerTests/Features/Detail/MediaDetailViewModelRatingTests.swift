import Testing
import Foundation
@testable import WatchTracker

/// Covers the Detail paths `MediaDetailViewModelTests` doesn't reach: ratings,
/// recommendations, season opening, cache reconciliation and analytics.
@MainActor
@Suite("MediaDetailViewModel (supplemental)", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
struct MediaDetailViewModelSupplementalTests {

    private struct Harness {
        let detail = MockMediaDetailService()
        let watchlist = MockWatchlistService()
        let store = WatchlistStore()
        let analytics = MockAnalytics()
        let viewModel: MediaDetailViewModel

        /// The title is construction-time identity now, so the harness takes it rather
        /// than each `load(...)` call.
        init(type: MediaType = .movie, id: Int = 550) {
            viewModel = MediaDetailViewModel(
                mediaType: type,
                mediaId: id,
                mediaDetailService: detail,
                watchlistService: watchlist,
                store: store,
                analytics: analytics
            )
        }

        func load(media: MediaDetail? = nil) async {
            if let media { detail.fetchMediaDetailResult = .success(media) }
            await viewModel.fetchDetails()
        }
    }

    // MARK: - Recommendations

    @Test func `fetchRecommendations populates the list`() async {
        let harness = Harness()
        harness.detail.fetchRecommendationsResult = .success([
            TestFixtures.mediaDetail(id: 1),
            TestFixtures.mediaDetail(id: 2),
        ])

        await harness.viewModel.fetchRecommendations()

        #expect(harness.viewModel.recommendations.map(\.id) == [1, 2])
        #expect(harness.detail.fetchRecommendationsCalls.count == 1)
        #expect(harness.detail.fetchRecommendationsCalls.first?.id == 550)
    }

    @Test func `fetchRecommendations fails silently to an empty list`() async {
        let harness = Harness()
        harness.detail.fetchRecommendationsResult = .success([TestFixtures.mediaDetail()])
        await harness.viewModel.fetchRecommendations()

        harness.detail.fetchRecommendationsResult = .failure(MockError.generic("boom"))
        await harness.viewModel.fetchRecommendations()

        #expect(harness.viewModel.recommendations.isEmpty)
        #expect(harness.viewModel.actionError == nil, "Recommendations are non-essential")
    }

    // MARK: - Rating

    @Test func `rateMedia updates the rating and calls the service`() async {
        let harness = Harness()
        await harness.load()

        await harness.viewModel.rateMedia(rating: 9)

        #expect(harness.viewModel.userRating == 9)
        #expect(harness.detail.rateMediaCalls.count == 1)
        #expect(harness.detail.rateMediaCalls.first?.rating == 9)
    }

    @Test func `rateMedia rolls back the optimistic update on failure`() async {
        let harness = Harness()
        await harness.load()
        await harness.viewModel.rateMedia(rating: 7)

        harness.detail.rateMediaError = MockError.generic("boom")
        await harness.viewModel.rateMedia(rating: 10)

        #expect(harness.viewModel.userRating == 7, "Should restore the previous rating")
        #expect(harness.viewModel.actionError != nil)
    }

    @Test func `rateMedia captures an analytics event`() async {
        let harness = Harness(type: .tv, id: 1399)
        await harness.load()

        await harness.viewModel.rateMedia(rating: 8)

        let properties = harness.analytics.properties(for: .mediaRated)
        #expect(properties?["media_type"] as? String == "tv")
        #expect(properties?["media_id"] as? Int == 1399)
        #expect(properties?["rating"] as? Int == 8)
    }

    @Test func `a failed rating captures no analytics event`() async {
        let harness = Harness()
        await harness.load()
        harness.detail.rateMediaError = MockError.generic("boom")

        await harness.viewModel.rateMedia(rating: 8)

        #expect(!harness.analytics.capturedEvents.contains(.mediaRated))
    }

    // MARK: - Remove rating

    @Test func `removeRating clears the rating and calls the service`() async {
        let harness = Harness()
        await harness.load()
        await harness.viewModel.rateMedia(rating: 9)

        await harness.viewModel.removeRating()

        #expect(harness.viewModel.userRating == nil)
        #expect(harness.detail.removeRatingCalls.count == 1)
        #expect(harness.detail.removeRatingCalls.first?.id == 550)
    }

    @Test func `removeRating restores the rating on failure`() async {
        let harness = Harness()
        await harness.load()
        await harness.viewModel.rateMedia(rating: 9)
        harness.detail.removeRatingError = MockError.generic("boom")

        await harness.viewModel.removeRating()

        #expect(harness.viewModel.userRating == 9)
        #expect(harness.viewModel.actionError != nil)
    }

    @Test func `removeRating captures an analytics event`() async {
        let harness = Harness()
        await harness.load()

        await harness.viewModel.removeRating()

        #expect(harness.analytics.capturedEvents.contains(.ratingRemoved))
    }

    // MARK: - Detail fetch analytics

    @Test func `fetchDetails captures a detailViewed event`() async {
        let harness = Harness()
        await harness.load(media: TestFixtures.mediaDetail(id: 550, title: "Fight Club"))

        let properties = harness.analytics.properties(for: .detailViewed)
        #expect(properties?["media_type"] as? String == "movie")
        #expect(properties?["media_id"] as? Int == 550)
        #expect(properties?["title"] as? String == "Fight Club")
    }

    @Test func `a failed fetchDetails captures no analytics event`() async {
        let harness = Harness()
        harness.detail.fetchMediaDetailResult = .failure(MockError.generic("boom"))

        await harness.viewModel.fetchDetails()

        #expect(harness.analytics.capturedEvents.isEmpty)
        guard case .failed = harness.viewModel.state else {
            return #expect(Bool(false), "expected .failed")
        }
    }

    // MARK: - Cache reconciliation

    @Test func `syncing from cache picks the newest duplicate row`() async {
        // Legacy data can hold duplicate rows for one (tmdbId, mediaType); the highest
        // id is the most recently created one.
        let harness = Harness()
        harness.store.cachedItems = [
            TestFixtures.watchItem(id: 3, tmdbId: 550, mediaType: .movie, status: .planToWatch),
            TestFixtures.watchItem(id: 9, tmdbId: 550, mediaType: .movie, status: .completed),
            TestFixtures.watchItem(id: 5, tmdbId: 550, mediaType: .movie, status: .watching),
        ]
        await harness.load()

        await harness.viewModel.checkWatchlistStatus()

        #expect(harness.viewModel.entry == WatchlistEntry(id: 9, status: .completed))
    }

    @Test func `a cache entry of the other media type is ignored`() async {
        let harness = Harness()
        harness.store.cachedItems = [
            TestFixtures.watchItem(id: 1, tmdbId: 550, mediaType: .tv, status: .watching),
        ]
        await harness.load()

        await harness.viewModel.checkWatchlistStatus()

        #expect(harness.viewModel.entry == nil)
    }

    // MARK: - Watchlist mutations

    @Test func `adding a new entry calls addToWatchlist and captures watchlistAdded`() async {
        let harness = Harness()
        await harness.load()

        await harness.viewModel.addToWatchlist(status: .planToWatch)

        #expect(harness.watchlist.addToWatchlistCalls.count == 1)
        #expect(harness.watchlist.updateStatusCalls.count == 0)
        #expect(harness.analytics.capturedEvents.contains(.watchlistAdded))
    }

    @Test func `changing an existing entry calls updateStatus and captures a status change`() async {
        let harness = Harness()
        harness.store.cachedItems = [
            TestFixtures.watchItem(id: 7, tmdbId: 550, mediaType: .movie, status: .planToWatch),
        ]
        await harness.load()
        await harness.viewModel.checkWatchlistStatus()

        await harness.viewModel.addToWatchlist(status: .completed)

        #expect(harness.watchlist.updateStatusCalls.count == 1)
        #expect(harness.watchlist.addToWatchlistCalls.count == 0)
        #expect(harness.analytics.capturedEvents.contains(.watchlistStatusChanged))
    }

    @Test func `completing a show marks every cached episode watched`() async {
        let harness = Harness(type: .tv, id: 1399)
        harness.detail.seasonResults[1] = TestFixtures.season(seasonNumber: 1, episodes: [
            TestFixtures.episode(id: 1, episodeNumber: 1),
            TestFixtures.episode(id: 2, episodeNumber: 2)
        ])
        await harness.load(media: TestFixtures.tvDetail(id: 1399, seasons: [(1, 2)]))
        await harness.viewModel.loadSeasonIfNeeded(1)

        await harness.viewModel.addToWatchlist(status: .completed)

        #expect(harness.watchlist.markAllEpisodesWatchedCalls.count == 1)
        #expect(harness.viewModel.episodes(inSeason: 1).allSatisfy { $0.isWatched })
    }

    @Test func `completing a movie does not bulk-mark episodes`() async {
        let harness = Harness()
        await harness.load()

        await harness.viewModel.addToWatchlist(status: .completed)

        #expect(harness.watchlist.markAllEpisodesWatchedCalls.count == 0)
    }

    @Test func `removeFromWatchlist is a no-op without a watchlist entry`() async {
        let harness = Harness()
        await harness.load()

        await harness.viewModel.removeFromWatchlist()

        #expect(harness.watchlist.removeFromWatchlistCalls.count == 0)
    }

    @Test func `removeFromWatchlist clears local state and captures the event`() async {
        let harness = Harness()
        harness.store.cachedItems = [
            TestFixtures.watchItem(id: 7, tmdbId: 550, mediaType: .movie, status: .watching),
        ]
        await harness.load()
        await harness.viewModel.checkWatchlistStatus()
        harness.watchlist.fetchWatchlistResult = .success([])

        await harness.viewModel.removeFromWatchlist()

        #expect(harness.viewModel.entry == nil)
        #expect(harness.viewModel.isOnWatchlist == false)
        #expect(harness.analytics.capturedEvents.contains(.watchlistRemoved))
    }

    // MARK: - openFirstUnwatchedSeason

    @Test func `openFirstUnwatchedSeason targets the first season with unwatched episodes`() async {
        let harness = Harness(type: .tv, id: 1399)
        harness.detail.seasonResults = [
            1: TestFixtures.season(seasonNumber: 1, episodes: [TestFixtures.episode(id: 1, episodeNumber: 1)]),
            2: TestFixtures.season(seasonNumber: 2, episodes: [TestFixtures.episode(id: 2, episodeNumber: 1)])
        ]
        // Season 1 fully watched, season 2 not.
        harness.detail.watchedEpisodesBySeason = [1: [1], 2: []]
        await harness.load(media: TestFixtures.tvDetail(id: 1399, seasons: [(1, 1), (2, 1)]))

        await harness.viewModel.openFirstUnwatchedSeason()

        #expect(harness.viewModel.scrollTargetSeason == 2)
        #expect(harness.viewModel.expandedSeasons.contains(2))
    }

    @Test func `openFirstUnwatchedSeason falls back to the first season when all are watched`() async {
        let harness = Harness(type: .tv, id: 1399)
        harness.detail.seasonResults = [
            1: TestFixtures.season(seasonNumber: 1, episodes: [TestFixtures.episode(id: 1, episodeNumber: 1)]),
            2: TestFixtures.season(seasonNumber: 2, episodes: [TestFixtures.episode(id: 2, episodeNumber: 1)])
        ]
        harness.detail.watchedEpisodesBySeason = [1: [1], 2: [1]]
        await harness.load(media: TestFixtures.tvDetail(id: 1399, seasons: [(1, 1), (2, 1)]))

        await harness.viewModel.openFirstUnwatchedSeason()

        #expect(harness.viewModel.scrollTargetSeason == 1)
    }

    @Test func `openFirstUnwatchedSeason skips seasons with no episodes`() async {
        // Season 0 is the specials bucket and often reports zero episodes.
        let harness = Harness(type: .tv, id: 1399)
        harness.detail.seasonResults[1] = TestFixtures.season(
            seasonNumber: 1,
            episodes: [TestFixtures.episode(id: 1, episodeNumber: 1)]
        )
        await harness.load(media: TestFixtures.tvDetail(id: 1399, seasons: [(0, 0), (1, 1)]))

        await harness.viewModel.openFirstUnwatchedSeason()

        #expect(harness.viewModel.scrollTargetSeason == 1)
        #expect(harness.detail.fetchSeasonDetailCalls.contains { $0.season == 0 } == false)
    }

    @Test func `openFirstUnwatchedSeason is a no-op for movies`() async {
        let harness = Harness()
        await harness.load()

        await harness.viewModel.openFirstUnwatchedSeason()

        #expect(harness.viewModel.scrollTargetSeason == nil)
    }

    // MARK: - Reentrancy

    /// Tapping the menu twice before the server answers must not send two writes.
    @Test func `addToWatchlist ignores a concurrent call`() async {
        let harness = Harness()
        await harness.load()

        // Runs inside the first request, which is the only window where the guard applies.
        harness.watchlist.duringAdd = { [viewModel = harness.viewModel] in
            await viewModel.addToWatchlist(status: .watching)
        }

        await harness.viewModel.addToWatchlist(status: .watching)

        #expect(harness.watchlist.addToWatchlistCalls.count == 1)
    }
}
