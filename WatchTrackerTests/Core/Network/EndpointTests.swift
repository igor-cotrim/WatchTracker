import Testing
import Foundation
@testable import WatchTracker

@Suite(.tags(.pure, .model))
struct EndpointTests {

    // MARK: - Paths

    @Test func `watchlist path`() {
        #expect(Endpoint.watchlist().path == "/watchlist")
    }

    @Test func `continueWatching path`() {
        #expect(Endpoint.continueWatching.path == "/watchlist/continue-watching")
    }

    @Test func `watchlistUpcoming path`() {
        #expect(Endpoint.watchlistUpcoming.path == "/watchlist/upcoming")
    }

    @Test func `addToWatchlist path`() {
        #expect(Endpoint.addToWatchlist(tmdbId: 1, mediaType: .movie, status: .planToWatch).path == "/watchlist")
    }

    @Test func `removeFromWatchlist path includes id`() {
        #expect(Endpoint.removeFromWatchlist(id: 42).path == "/watchlist/42")
    }

    @Test func `updateWatchlistStatus path includes id and status segment`() {
        #expect(Endpoint.updateWatchlistStatus(id: 7, status: .watching).path == "/watchlist/7/status")
    }

    @Test func `mediaDetail movie path`() {
        #expect(Endpoint.mediaDetail(type: .movie, id: 99).path == "/media/movie/99")
    }

    @Test func `mediaDetail tv path`() {
        #expect(Endpoint.mediaDetail(type: .tv, id: 5).path == "/media/tv/5")
    }

    @Test func `watchEpisode path`() {
        #expect(Endpoint.watchEpisode(tvId: 1, season: 2, episode: 3).path == "/media/tv/1/episodes/2/3/watch")
    }

    @Test func `unwatchEpisode path`() {
        #expect(Endpoint.unwatchEpisode(tvId: 10, season: 1, episode: 5).path == "/media/tv/10/episodes/1/5/watch")
    }

    @Test func `watchSeason path`() {
        #expect(Endpoint.watchSeason(tvId: 10, season: 2).path == "/media/tv/10/seasons/2/watch")
    }

    @Test func `unwatchSeason path`() {
        #expect(Endpoint.unwatchSeason(tvId: 10, season: 2).path == "/media/tv/10/seasons/2/watch")
    }

    @Test func `watchAllEpisodes path`() {
        #expect(Endpoint.watchAllEpisodes(tvId: 7).path == "/media/tv/7/watch-all")
    }

    @Test func `seasonDetail path`() {
        #expect(Endpoint.seasonDetail(tvId: 10, season: 2).path == "/media/tv/10/season/2")
    }

    @Test func `watchedEpisodes path`() {
        #expect(Endpoint.watchedEpisodes(tvId: 10, season: 2).path == "/media/tv/10/seasons/2/watched")
    }

    @Test func `profileStats path`() {
        #expect(Endpoint.profileStats.path == "/profile/stats")
    }

    @Test func `trending path`() {
        #expect(Endpoint.trending(page: nil).path == "/discover/trending")
    }

    @Test func `search path`() {
        #expect(Endpoint.search(query: "batman", type: nil, year: nil).path == "/discover/search")
    }

    @Test func `nowPlaying path`() {
        #expect(Endpoint.nowPlaying(page: nil).path == "/discover/now-playing")
    }

    @Test func `topRated path`() {
        #expect(Endpoint.topRated(type: .movie, page: nil).path == "/discover/top-rated")
    }

    @Test func `upcoming path`() {
        #expect(Endpoint.upcoming(page: nil).path == "/discover/upcoming")
    }

    @Test func `popular path`() {
        #expect(Endpoint.popular(type: .movie, page: nil).path == "/discover/popular")
    }

    @Test func `genres path`() {
        #expect(Endpoint.genres(type: .movie).path == "/discover/genres")
    }

    @Test func `providers path`() {
        #expect(Endpoint.providers(type: .tv).path == "/discover/providers")
    }

    @Test func `discover path`() {
        #expect(Endpoint.discover(provider: nil, type: nil, region: nil).path == "/discover")
    }

    @Test func `discoverFiltered path`() {
        #expect(Endpoint.discoverFiltered(type: .tv, genres: nil, originCountry: nil, providers: nil, watchRegion: nil, sortBy: nil, page: nil, releaseDateGte: nil, firstAirDateGte: nil).path == "/discover")
    }

    // MARK: - Methods

    @Test(arguments: [
        (Endpoint.watchlist(), HTTPMethod.GET),
        (Endpoint.continueWatching, HTTPMethod.GET),
        (Endpoint.watchlistUpcoming, HTTPMethod.GET),
        (Endpoint.mediaDetail(type: .movie, id: 1), HTTPMethod.GET),
        (Endpoint.trending(page: nil), HTTPMethod.GET),
        (Endpoint.search(query: "x", type: nil, year: nil), HTTPMethod.GET),
        (Endpoint.profileStats, HTTPMethod.GET),
    ])
    func `GET endpoints`(endpoint: Endpoint, expected: HTTPMethod) {
        #expect(endpoint.method == expected)
    }

    @Test(arguments: [
        (Endpoint.addToWatchlist(tmdbId: 1, mediaType: .movie, status: .planToWatch), HTTPMethod.POST),
        (Endpoint.watchEpisode(tvId: 1, season: 1, episode: 1), HTTPMethod.POST),
        (Endpoint.watchSeason(tvId: 1, season: 1), HTTPMethod.POST),
        (Endpoint.watchAllEpisodes(tvId: 1), HTTPMethod.POST),
        (Endpoint.rateMedia(type: .movie, id: 1, rating: 5), HTTPMethod.POST),
    ])
    func `POST endpoints`(endpoint: Endpoint, expected: HTTPMethod) {
        #expect(endpoint.method == expected)
    }

    @Test(arguments: [
        (Endpoint.removeFromWatchlist(id: 1), HTTPMethod.DELETE),
        (Endpoint.unwatchEpisode(tvId: 1, season: 1, episode: 1), HTTPMethod.DELETE),
        (Endpoint.unwatchSeason(tvId: 1, season: 1), HTTPMethod.DELETE),
    ])
    func `DELETE endpoints`(endpoint: Endpoint, expected: HTTPMethod) {
        #expect(endpoint.method == expected)
    }

    @Test func `PATCH endpoint`() {
        #expect(Endpoint.updateWatchlistStatus(id: 1, status: .watching).method == .PATCH)
    }

    // MARK: - Query Items

    @Test func `watchlist with no filters has no query items`() {
        #expect(Endpoint.watchlist(status: nil, mediaType: nil).queryItems == nil)
    }

    @Test func `watchlist with status filter has status query item`() {
        let items = Endpoint.watchlist(status: .watching, mediaType: nil).queryItems
        let statusItem = items?.first { $0.name == "status" }
        #expect(statusItem?.value == "watching")
    }

    @Test func `watchlist with both filters has two query items`() {
        let items = Endpoint.watchlist(status: .watching, mediaType: "movie").queryItems
        #expect(items?.count == 2)
    }

    @Test func `search always includes query item`() {
        let items = Endpoint.search(query: "batman", type: nil, year: nil).queryItems
        let queryItem = items?.first { $0.name == "query" }
        #expect(queryItem?.value == "batman")
    }

    @Test func `search with type and year has three items`() {
        let items = Endpoint.search(query: "batman", type: .movie, year: 2020).queryItems
        #expect(items?.count == 3)
    }

    @Test func `discoverFiltered always includes type`() {
        let items = Endpoint.discoverFiltered(type: .tv, genres: nil, originCountry: nil, providers: nil, watchRegion: nil, sortBy: nil, page: nil, releaseDateGte: nil, firstAirDateGte: nil).queryItems
        let typeItem = items?.first { $0.name == "type" }
        #expect(typeItem?.value == "tv")
    }

    @Test func `discoverFiltered with all params has all query items`() {
        let items = Endpoint.discoverFiltered(type: .tv, genres: "16", originCountry: "JP", providers: nil, watchRegion: nil, sortBy: nil, page: nil, releaseDateGte: nil, firstAirDateGte: nil).queryItems
        let genresItem = items?.first { $0.name == "with_genres" }
        let countryItem = items?.first { $0.name == "with_origin_country" }
        #expect(genresItem?.value == "16")
        #expect(countryItem?.value == "JP")
    }

    @Test func `topRated without page has only type`() {
        let items = Endpoint.topRated(type: .movie, page: nil).queryItems
        #expect(items?.count == 1)
        #expect(items?.first?.name == "type")
    }

    @Test func `topRated with page has two items`() {
        let items = Endpoint.topRated(type: .movie, page: 2).queryItems
        #expect(items?.count == 2)
    }

    @Test func `upcoming without page has no query items`() {
        #expect(Endpoint.upcoming(page: nil).queryItems == nil)
    }

    @Test func `upcoming with page has one item`() {
        let items = Endpoint.upcoming(page: 3).queryItems
        #expect(items?.first?.value == "3")
    }

    // MARK: - Bodies

    @Test func `addToWatchlist has a body`() {
        #expect(Endpoint.addToWatchlist(tmdbId: 1, mediaType: .movie, status: .planToWatch).body != nil)
    }

    @Test func `rateMedia has a body`() {
        #expect(Endpoint.rateMedia(type: .movie, id: 1, rating: 5).body != nil)
    }

    @Test func `updateWatchlistStatus has a body`() {
        #expect(Endpoint.updateWatchlistStatus(id: 1, status: .watching).body != nil)
    }

    @Test func `trending has no body`() {
        #expect(Endpoint.trending(page: nil).body == nil)
    }

    @Test func `watchlist GET has no body`() {
        #expect(Endpoint.watchlist().body == nil)
    }

    @Test func `watchEpisode has no body`() {
        #expect(Endpoint.watchEpisode(tvId: 1, season: 1, episode: 1).body == nil)
    }
}
