import Testing
@testable import WatchTracker

@MainActor
@Suite("BrowseFeed", .tags(.pure, .async), .timeLimit(.minutes(1)))
struct BrowseFeedTests {

    private func detail(id: Int, releaseDate: String? = nil) -> MediaDetail {
        TestFixtures.mediaDetail(id: id, releaseDate: releaseDate)
    }

    // MARK: - Merge helpers

    @Test func `interleaved alternates between the two lists`() {
        let merged = MediaMerge.interleaved(
            [detail(id: 1), detail(id: 2)],
            [detail(id: 10), detail(id: 20)]
        )
        #expect(merged.map(\.id) == [1, 10, 2, 20])
    }

    @Test func `interleaved appends the remainder of the longer list`() {
        let merged = MediaMerge.interleaved(
            [detail(id: 1), detail(id: 2), detail(id: 3)],
            [detail(id: 10)]
        )
        #expect(merged.map(\.id) == [1, 10, 2, 3])
    }

    @Test func `interleaved handles an empty first list`() {
        #expect(MediaMerge.interleaved([], [detail(id: 10), detail(id: 20)]).map(\.id) == [10, 20])
    }

    @Test func `interleaved of two empty lists is empty`() {
        #expect(MediaMerge.interleaved([], []).isEmpty)
    }

    @Test func `byReleaseDateDesc sorts newest first`() {
        let merged = MediaMerge.byReleaseDateDesc(
            [detail(id: 1, releaseDate: "2020-01-01"), detail(id: 2, releaseDate: "2024-06-01")],
            [detail(id: 3, releaseDate: "2022-03-01")]
        )
        #expect(merged.map(\.id) == [2, 3, 1])
    }

    @Test func `byReleaseDateDesc sorts items without a date last`() {
        let merged = MediaMerge.byReleaseDateDesc(
            [detail(id: 1, releaseDate: nil)],
            [detail(id: 2, releaseDate: "2020-01-01")]
        )
        #expect(merged.map(\.id) == [2, 1])
    }

    @Test func `byReleaseDateDesc keeps every element`() {
        #expect(MediaMerge.byReleaseDateDesc([detail(id: 1), detail(id: 2)], [detail(id: 3)]).count == 3)
    }

    // MARK: - Queries
    //
    // These used to be written inside `DiscoverView` and `MoodBrowseView`, where nothing
    // could reach them.

    @Test func `a mood feed asks for both types with that mood's genres`() async throws {
        let service = MockDiscoverService()
        let mood = try #require(MoodPreset.all.first)

        _ = try await BrowseFeed.mood(mood).page(2, using: service)

        #expect(service.discoverFilteredCalls.count == 2)
        let movie = try #require(service.discoverFilteredCalls.first { $0.type == .movie })
        let tv = try #require(service.discoverFilteredCalls.first { $0.type == .tv })
        #expect(movie.genres == mood.genresQueryValue(for: .movie))
        #expect(tv.genres == mood.genresQueryValue(for: .tv))
        #expect(movie.sortBy == mood.sortBy)
        #expect(movie.page == 2)
    }

    /// One type, one request: the whole reason `DiscoverFilter` requires a media type is
    /// that merging two paginated responses would destroy the ordering the user picked.
    @Test func `a filtered feed is a single request carrying the whole filter`() async throws {
        let service = MockDiscoverService()
        var filter = DiscoverFilter(type: .tv)
        filter.genreIds = [9648]
        filter.sort = .rating

        _ = try await BrowseFeed.filtered(filter).page(2, using: service)

        #expect(service.discoverFilteredCalls.count == 1)
        let call = try #require(service.discoverFilteredCalls.first)
        #expect(call.type == .tv)
        #expect(call.genres == "9648")
        #expect(call.sortBy == "vote_average.desc")
        #expect(call.voteCountGte == 300)
        #expect(call.page == 2)
    }

    @Test func `a provider see-all feed is movies scoped to the region`() async throws {
        let service = MockDiscoverService()

        _ = try await BrowseFeed.providerMovies(id: 8, sortBy: "popularity.desc").page(3, using: service)

        let call = try #require(service.discoverFilteredCalls.first)
        #expect(service.discoverFilteredCalls.count == 1)
        #expect(call.type == .movie)
        #expect(call.providers == "8")
        #expect(call.watchRegion == MediaMerge.watchRegion)
        #expect(call.sortBy == "popularity.desc")
        #expect(call.page == 3)
    }

    @Test func `the trending feed forwards the page number`() async throws {
        let service = MockDiscoverService()
        _ = try await BrowseFeed.trending.page(4, using: service)
        #expect(service.trendingPagesRequested == [4])
    }

    // MARK: - Provider rows

    /// The "new on <provider>" row is the only one with a date window, and it applies a
    /// different cutoff field per type — movies release, shows first-air.
    @Test func `the new row windows each type on its own date field`() async throws {
        let service = MockDiscoverService()
        let provider = TestFixtures.streamingProvider(providerId: 8)

        _ = try await ProviderRow.new.load(provider: provider, since: "2026-01-01", using: service)

        let movie = try #require(service.discoverFilteredCalls.first { $0.type == .movie })
        let tv = try #require(service.discoverFilteredCalls.first { $0.type == .tv })
        #expect(movie.releaseDateGte == "2026-01-01")
        #expect(movie.firstAirDateGte == nil)
        #expect(tv.firstAirDateGte == "2026-01-01")
        #expect(tv.releaseDateGte == nil)
    }

    @Test func `the top ten row is capped at ten`() async throws {
        let service = MockDiscoverService()
        service.discoverFilteredResult = .success((1...12).map { detail(id: $0) })

        let items = try await ProviderRow.topTen.load(
            provider: TestFixtures.streamingProvider(providerId: 8),
            since: "2026-01-01",
            using: service
        )

        #expect(items.count == 10)
    }

    /// Page 2 on purpose: page 1 of popularity is already the top-ten row above it.
    @Test func `the trending row reads the second page of popularity`() async throws {
        let service = MockDiscoverService()

        _ = try await ProviderRow.trending.load(
            provider: TestFixtures.streamingProvider(providerId: 8),
            since: "2026-01-01",
            using: service
        )

        #expect(service.discoverFilteredCalls.allSatisfy { $0.page == 2 })
        #expect(service.discoverFilteredCalls.allSatisfy { $0.sortBy == "popularity.desc" })
    }

    @Test func `the acclaimed row sorts by score`() async throws {
        let service = MockDiscoverService()

        _ = try await ProviderRow.acclaimed.load(
            provider: TestFixtures.streamingProvider(providerId: 8),
            since: "2026-01-01",
            using: service
        )

        #expect(service.discoverFilteredCalls.allSatisfy { $0.sortBy == "vote_average.desc" })
    }

    @Test(arguments: ProviderRow.allCases)
    func `every row's see-all grid keeps its ordering`(row: ProviderRow) {
        guard case .providerMovies(let id, let sortBy) = row.seeAllFeed(
            provider: TestFixtures.streamingProvider(providerId: 8)
        ) else {
            return #expect(Bool(false), "expected a provider grid")
        }
        #expect(id == 8)
        #expect(!sortBy.isEmpty)
    }

    @Test func `only the top ten row is ranked`() {
        #expect(ProviderRow.allCases.filter(\.isRanked) == [.topTen])
    }
}
