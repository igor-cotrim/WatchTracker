import Testing
@testable import WatchTracker

@Suite("DiscoverFilter", .tags(.model, .pure))
struct DiscoverFilterTests {

    // MARK: - Query construction

    @Test func `a default filter asks for popular movies and nothing else`() {
        let query = DiscoverFilter().query(page: nil)

        #expect(query.type == .movie)
        #expect(query.sortBy == "popularity.desc")
        #expect(query.genres == nil)
        #expect(query.providers == nil)
        #expect(query.watchRegion == nil)
        #expect(query.originCountry == nil)
        #expect(query.voteCountGte == nil)
    }

    @Test func `genres join with a comma, which is AND in TMDB`() {
        var filter = DiscoverFilter()
        filter.genreIds = [53, 18]

        #expect(filter.query(page: nil).genres == "18,53")
    }

    @Test func `providers join with a pipe, which is OR in TMDB`() {
        var filter = DiscoverFilter()
        filter.providerIds = [8, 337]

        #expect(filter.query(page: nil).providers == "8|337")
    }

    /// TMDB scopes provider availability by country, so the region is meaningless — and
    /// would needlessly narrow the result — until a provider is actually picked.
    @Test func `the watch region is only sent alongside a provider`() {
        var filter = DiscoverFilter()
        #expect(filter.query(page: nil).watchRegion == nil)

        filter.providerIds = [8]
        #expect(filter.query(page: nil).watchRegion == MediaMerge.watchRegion)
    }

    @Test func `the release window lands on the date field belonging to the type`() {
        var filter = DiscoverFilter(type: .movie)
        filter.releaseWindow = .decade1990s
        let movie = filter.query(page: nil)

        #expect(movie.releaseDateGte == "1990-01-01")
        #expect(movie.releaseDateLte == "1999-12-31")
        #expect(movie.firstAirDateGte == nil)
        #expect(movie.firstAirDateLte == nil)

        filter.type = .tv
        let show = filter.query(page: nil)

        #expect(show.firstAirDateGte == "1990-01-01")
        #expect(show.firstAirDateLte == "1999-12-31")
        #expect(show.releaseDateGte == nil)
        #expect(show.releaseDateLte == nil)
    }

    @Test func `the page number is forwarded so the grid can paginate`() {
        #expect(DiscoverFilter().query(page: 4).page == 4)
    }

    // MARK: - Anime

    /// TMDB has no anime type, so the option resolves to Japanese animated series.
    @Test func `anime queries series pinned to Japan and animation`() {
        let query = DiscoverFilter(type: .anime).query(page: nil)

        #expect(query.type == .tv)
        #expect(query.originCountry == "JP")
        #expect(query.genres == "16")
    }

    @Test func `anime narrows further with another genre instead of replacing it`() {
        var filter = DiscoverFilter(type: .anime)
        filter.genreIds = [9648]
        let query = filter.query(page: nil)

        #expect(query.genres == "16,9648")
        #expect(query.originCountry == "JP")
    }

    @Test func `only anime pins an origin country`() {
        #expect(DiscoverFilter(type: .movie).query(page: nil).originCountry == nil)
        #expect(DiscoverFilter(type: .tv).query(page: nil).originCountry == nil)
    }

    // MARK: - Badge

    @Test func `the type does not count as an active criterion`() {
        for type in DiscoverType.allCases {
            #expect(DiscoverFilter(type: type).activeCriteriaCount == 0)
        }
    }

    @Test func `every other criterion counts toward the badge`() {
        var filter = DiscoverFilter()
        filter.genreIds = [53, 18]
        filter.providerIds = [8]
        filter.sort = .rating
        filter.releaseWindow = .decade2010s

        #expect(filter.activeCriteriaCount == 5)
    }
}

@Suite("DiscoverSort", .tags(.model, .pure))
struct DiscoverSortTests {

    /// Without a floor, `vote_average.desc` hands back obscure titles carrying a handful
    /// of perfect scores — the bug this filter would otherwise ship with.
    @Test func `only the rating sort asks TMDB for a minimum vote count`() {
        #expect(DiscoverSort.rating.minimumVoteCount == 300)
        for sort in DiscoverSort.allCases where sort != .rating {
            #expect(sort.minimumVoteCount == nil)
        }
    }

    @Test func `a rating sort carries its vote floor into the query`() {
        var filter = DiscoverFilter()
        filter.sort = .rating

        #expect(filter.query(page: nil).voteCountGte == 300)
    }

    @Test(arguments: [
        (DiscoverSort.popularity, "popularity.desc", "popularity.desc"),
        (.rating, "vote_average.desc", "vote_average.desc"),
        (.newest, "primary_release_date.desc", "first_air_date.desc"),
        (.titleAZ, "title.asc", "name.asc")
    ])
    func `each sort maps to the TMDB key for its media type`(
        sort: DiscoverSort, movieKey: String, tvKey: String
    ) {
        #expect(sort.queryValue(for: .movie) == movieKey)
        #expect(sort.queryValue(for: .tv) == tvKey)
    }
}

@Suite("ReleaseWindow", .tags(.model, .pure))
struct ReleaseWindowTests {

    @Test func `any time is open at both ends`() {
        #expect(ReleaseWindow.any.from == nil)
        #expect(ReleaseWindow.any.until == nil)
    }

    @Test func `before 1980 is open at the start only`() {
        #expect(ReleaseWindow.before1980.from == nil)
        #expect(ReleaseWindow.before1980.until == "1979-12-31")
    }

    @Test(arguments: [
        (ReleaseWindow.decade2020s, "2020-01-01", "2029-12-31"),
        (.decade2010s, "2010-01-01", "2019-12-31"),
        (.decade2000s, "2000-01-01", "2009-12-31"),
        (.decade1990s, "1990-01-01", "1999-12-31"),
        (.decade1980s, "1980-01-01", "1989-12-31")
    ])
    func `each decade spans its full ten years`(
        window: ReleaseWindow, from: String, until: String
    ) {
        #expect(window.from == from)
        #expect(window.until == until)
    }
}
