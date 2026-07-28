import Foundation
import Testing
@testable import WatchTracker

/// Covers the endpoint cases and behaviours `EndpointTests` doesn't reach.
@Suite("Endpoint (supplemental)", .tags(.pure))
struct EndpointCoverageTests {

    // MARK: Previously uncovered paths

    @Test func `mediaRecommendations path`() {
        #expect(Endpoint.mediaRecommendations(type: .tv, id: 1399).path == "/media/tv/1399/recommendations")
    }

    @Test func `rateMedia path`() {
        #expect(Endpoint.rateMedia(type: .movie, id: 550, rating: 9).path == "/media/movie/550/rate")
    }

    @Test func `removeRating path`() {
        #expect(Endpoint.removeRating(type: .movie, id: 550).path == "/media/movie/550/rate")
    }

    @Test func `deleteAccount path`() {
        #expect(Endpoint.deleteAccount.path == "/profile")
    }

    @Test func `importData path`() {
        #expect(Endpoint.importData(batch: ImportBatch()).path == "/import")
    }

    // MARK: Method disambiguates same-path pairs

    @Test func `rate and unrate share a path but differ by method`() {
        let rate = Endpoint.rateMedia(type: .movie, id: 550, rating: 9)
        let unrate = Endpoint.removeRating(type: .movie, id: 550)

        #expect(rate.path == unrate.path)
        #expect(rate.method == .POST)
        #expect(unrate.method == .DELETE)
    }

    @Test func `watch and unwatch episode share a path but differ by method`() {
        let watch = Endpoint.watchEpisode(tvId: 1, season: 2, episode: 3)
        let unwatch = Endpoint.unwatchEpisode(tvId: 1, season: 2, episode: 3)

        #expect(watch.path == unwatch.path)
        #expect(watch.method == .POST)
        #expect(unwatch.method == .DELETE)
    }

    @Test func `watch and unwatch season share a path but differ by method`() {
        let watch = Endpoint.watchSeason(tvId: 1, season: 2)
        let unwatch = Endpoint.unwatchSeason(tvId: 1, season: 2)

        #expect(watch.path == unwatch.path)
        #expect(watch.method == .POST)
        #expect(unwatch.method == .DELETE)
    }

    @Test func `discover and discoverFiltered share the discover path`() {
        let plain = Endpoint.discover(provider: nil, type: nil, region: nil)
        let filtered = Endpoint.discoverFiltered(
            type: .movie, genres: nil, originCountry: nil, providers: nil,
            watchRegion: nil, sortBy: nil, page: nil,
            releaseDateGte: nil, firstAirDateGte: nil
        )
        #expect(plain.path == filtered.path)
        #expect(plain.method == .GET)
        #expect(filtered.method == .GET)
    }

    @Test(arguments: [
        Endpoint.removeFromWatchlist(id: 1),
        .removeRating(type: .movie, id: 1),
        .unwatchEpisode(tvId: 1, season: 1, episode: 1),
        .unwatchSeason(tvId: 1, season: 1),
        .deleteAccount,
    ])
    func `destructive endpoints use DELETE`(endpoint: Endpoint) {
        #expect(endpoint.method == .DELETE)
    }

    // MARK: Bodies

    private func bodyJSON(_ endpoint: Endpoint) throws -> [String: Any] {
        let body = try #require(endpoint.body)
        let data = try APIClient.makeEncoder().encode(body)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test func `addToWatchlist body encodes to snake_case`() throws {
        let json = try bodyJSON(.addToWatchlist(tmdbId: 550, mediaType: .movie, status: .planToWatch))
        #expect(json["tmdb_id"] as? Int == 550)
        #expect(json["media_type"] as? String == "movie")
        #expect(json["status"] as? String == "plan_to_watch")
    }

    @Test func `rateMedia body carries the rating`() throws {
        let json = try bodyJSON(.rateMedia(type: .movie, id: 550, rating: 9))
        #expect(json["rating"] as? Int == 9)
    }

    @Test func `updateWatchlistStatus body carries the status`() throws {
        let json = try bodyJSON(.updateWatchlistStatus(id: 1, status: .completed))
        #expect(json["status"] as? String == "completed")
    }

    @Test func `importData body tags the source and carries the items`() throws {
        let json = try bodyJSON(.importData(batch: ImportBatch(items: [
            TestFixtures.importItem(title: "Dune", year: 2021),
        ])))
        #expect(json["source"] as? String == "letterboxd")
        let items = try #require(json["items"] as? [[String: Any]])
        #expect(items.count == 1)
        #expect(items.first?["title"] as? String == "Dune")
    }

    @Test func `importData body tags a batch carrying TMDB ids as watchtracker`() throws {
        let batch = ImportBatch(
            items: [TestFixtures.importItem(title: "Severance", tmdbId: 95396, mediaType: .tv)],
            episodes: [ImportEpisode(tmdbId: 95396, seasonNumber: 1, episodeNumber: 1, watchedDate: nil)]
        )
        let json = try bodyJSON(.importData(batch: batch))

        #expect(json["source"] as? String == "watchtracker")
        let items = try #require(json["items"] as? [[String: Any]])
        #expect(items.first?["tmdb_id"] as? Int == 95396)
        #expect(items.first?["media_type"] as? String == "tv")
        let episodes = try #require(json["episodes"] as? [[String: Any]])
        #expect(episodes.first?["season_number"] as? Int == 1)
    }

    @Test(arguments: [
        Endpoint.removeRating(type: .movie, id: 1),
        .deleteAccount,
        .mediaRecommendations(type: .tv, id: 1),
        .unwatchSeason(tvId: 1, season: 1),
        .profileStats,
    ])
    func `endpoints without a payload have no body`(endpoint: Endpoint) {
        #expect(endpoint.body == nil)
    }

    // MARK: Query items

    @Test func `discoverFiltered uses TMDB dotted date parameter names`() {
        let endpoint = Endpoint.discoverFiltered(
            type: .movie, genres: nil, originCountry: nil, providers: nil,
            watchRegion: nil, sortBy: nil, page: nil,
            releaseDateGte: "2026-01-01", firstAirDateGte: "2026-02-01"
        )
        let names = (endpoint.queryItems ?? []).map(\.name)
        #expect(names.contains("primary_release_date.gte"))
        #expect(names.contains("first_air_date.gte"))
    }

    @Test func `mediaRecommendations has no query items`() {
        #expect(Endpoint.mediaRecommendations(type: .tv, id: 1).queryItems == nil)
    }

    @Test func `discover with no filters has no query items`() {
        #expect(Endpoint.discover(provider: nil, type: nil, region: nil).queryItems == nil)
    }

    @Test func `discover includes each provided filter`() {
        let items = Endpoint.discover(provider: "8", type: .tv, region: "BR").queryItems ?? []
        #expect(items.count == 3)
        #expect(items.contains { $0.name == "provider" && $0.value == "8" })
        #expect(items.contains { $0.name == "type" && $0.value == "tv" })
        #expect(items.contains { $0.name == "region" && $0.value == "BR" })
    }
}
