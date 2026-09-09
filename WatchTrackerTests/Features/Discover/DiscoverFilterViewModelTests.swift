import Testing
@testable import WatchTracker

@MainActor
@Suite("DiscoverFilterViewModel", .tags(.viewModel, .async))
struct DiscoverFilterViewModelTests {

    private func viewModel(
        initialFilter: DiscoverFilter = DiscoverFilter(),
        service: MockDiscoverService? = nil,
        analytics: MockAnalytics? = nil
    ) -> DiscoverFilterViewModel {
        DiscoverFilterViewModel(
            initialFilter: initialFilter,
            service: service ?? MockDiscoverService(),
            analytics: analytics ?? MockAnalytics()
        )
    }

    // MARK: - Loading

    @Test func `load fills the genre and provider lists`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .success([Genre(id: 53, name: "Thriller")])
        service.fetchProvidersResult = .success([TestFixtures.streamingProvider(providerId: 8)])
        let sut = viewModel(service: service)

        await sut.load()

        #expect(sut.genres.map(\.id) == [53])
        #expect(sut.providers.map(\.providerId) == [8])
    }

    /// A failed genre list hides that section rather than blocking the sheet — the other
    /// criteria still work.
    @Test func `a failed genre load leaves the section empty instead of erroring`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .failure(APIError.serverError)
        let sut = viewModel(service: service)

        await sut.load()

        #expect(sut.genres.isEmpty)
        #expect(sut.isLoadingGenres == false)
    }

    @Test func `the sheet opens on the filter it was given`() {
        var filter = DiscoverFilter(type: .tv)
        filter.sort = .rating

        let sut = viewModel(initialFilter: filter)

        #expect(sut.draft.type == .tv)
        #expect(sut.draft.sort == .rating)
    }

    // MARK: - Type changes

    /// Genre ids mean different things per type — 28 is Action for a movie, a show uses
    /// 10759 — so carrying the selection across would silently query for the wrong thing.
    @Test func `switching the type drops the genre selection`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .success([Genre(id: 28, name: "Action")])
        let sut = viewModel(service: service)
        await sut.load()
        sut.toggleGenre(28)

        sut.selectType(.tv)

        #expect(sut.draft.genreIds.isEmpty)
        #expect(sut.draft.type == .tv)
    }

    /// Series and anime are the same TMDB type, so the genre list they offer is identical —
    /// reloading it (and dropping the picks) would be busywork the user feels as a flicker.
    @Test func `switching between series and anime keeps the genres`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .success([Genre(id: 9648, name: "Mistério")])
        let sut = viewModel(initialFilter: DiscoverFilter(type: .tv), service: service)
        await sut.load()
        sut.toggleGenre(9648)

        sut.selectType(.anime)

        #expect(sut.draft.type == .anime)
        #expect(sut.draft.genreIds == [9648])
        #expect(sut.genres.map(\.id) == [9648])
    }

    @Test func `switching from a movie to anime reloads the series genres`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .success([Genre(id: 10759, name: "Ação e Aventura")])
        let sut = viewModel(service: service)

        sut.selectType(.anime)
        await sut.genresTask?.value

        #expect(sut.genres.map(\.id) == [10759])
    }

    @Test func `switching the type reloads the genre list for it`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .success([Genre(id: 10759, name: "Action & Adventure")])
        let sut = viewModel(service: service)

        sut.selectType(.tv)
        await sut.genresTask?.value

        #expect(sut.genres.map(\.id) == [10759])
    }

    @Test func `selecting the type already in use changes nothing`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .success([Genre(id: 28, name: "Action")])
        let sut = viewModel(service: service)
        await sut.load()
        sut.toggleGenre(28)

        sut.selectType(.movie)

        #expect(sut.draft.genreIds == [28])
        #expect(sut.genresTask == nil)
    }

    // MARK: - Selection

    @Test func `toggling a genre adds it and toggling again removes it`() {
        let sut = viewModel()

        sut.toggleGenre(53)
        #expect(sut.draft.genreIds == [53])

        sut.toggleGenre(53)
        #expect(sut.draft.genreIds.isEmpty)
    }

    @Test func `toggling a provider adds it and toggling again removes it`() {
        let sut = viewModel()

        sut.toggleProvider(8)
        #expect(sut.draft.providerIds == [8])

        sut.toggleProvider(8)
        #expect(sut.draft.providerIds.isEmpty)
    }

    // MARK: - Clearing

    /// Clearing keeps the type: "no type" is not a state the filter has, and dropping it
    /// would also throw away the genre list already loaded for it.
    @Test func `clearing resets every criterion but the media type`() async {
        let service = MockDiscoverService()
        service.fetchGenresResult = .success([Genre(id: 10759, name: "Action & Adventure")])
        let sut = viewModel(initialFilter: DiscoverFilter(type: .tv), service: service)
        sut.toggleGenre(10759)
        sut.toggleProvider(8)
        sut.selectSort(.rating)
        sut.selectReleaseWindow(.decade1990s)

        sut.clearAll()

        #expect(sut.draft.type == .tv)
        #expect(sut.draft.activeCriteriaCount == 0)
    }

    // MARK: - Applying

    @Test func `applying returns the draft the user built`() {
        let sut = viewModel()
        sut.toggleGenre(53)
        sut.selectSort(.rating)

        let filter = sut.apply()

        #expect(filter.genreIds == [53])
        #expect(filter.sort == .rating)
    }

    @Test func `applying reports what was filtered on`() throws {
        let analytics = MockAnalytics()
        let sut = viewModel(analytics: analytics)
        sut.selectType(.anime)
        sut.toggleGenre(9648)
        sut.selectSort(.rating)

        _ = sut.apply()

        let properties = try #require(analytics.properties(for: .discoverFilterApplied))
        #expect(properties["type"] as? String == "anime")
        #expect(properties["genre_count"] as? Int == 1)
        #expect(properties["sort"] as? String == "rating")
    }
}
