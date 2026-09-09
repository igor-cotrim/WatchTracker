import SwiftUI
import Testing
@testable import WatchTracker

/// Renders every component in `Features/Detail/Components/`. All 15 were at 0% coverage.
///
/// The sections that take a `MediaDetailViewModel` get a real one wired to mocks, so no
/// request leaves the process. `render(_:)` does not appear the view, so none of the
/// `.task` bodies run either — see `RenderHostTests`.
///
/// The view model's state is `private(set)`, so the in-flight states below are reached by
/// rendering *inside* the mock's `duringCall` hook — the one moment those flags are set —
/// rather than by assigning them from the test.
@MainActor
@Suite("Detail components render", .tags(.view, .pure))
struct DetailComponentRenderTests {

    private func makeVM(
        type: MediaType = .movie,
        id: Int = 1,
        service: MockMediaDetailService? = nil,
        watchlistService: MockWatchlistService? = nil,
        store: WatchlistStore? = nil
    ) -> MediaDetailViewModel {
        MediaDetailViewModel(
            mediaType: type,
            mediaId: id,
            mediaDetailService: service ?? MockMediaDetailService(),
            watchlistService: watchlistService ?? MockWatchlistService(),
            store: store ?? WatchlistStore(),
            outbox: MutationOutbox(),
            analytics: MockAnalytics()
        )
    }

    /// A TV view model with season 1's episodes loaded through the mock.
    private func tvVM(
        _ service: MockMediaDetailService,
        episodes: [Episode],
        watched: [Int] = []
    ) async -> MediaDetailViewModel {
        service.fetchSeasonDetailResult = .success(TestFixtures.season(episodes: episodes))
        service.fetchWatchedEpisodesResult = .success(watched)
        let vm = makeVM(type: .tv, id: 2, service: service)
        await vm.loadSeasonIfNeeded(1)
        return vm
    }

    private var movie: MediaDetail {
        TestFixtures.mediaDetail(posterPath: nil, backdropPath: nil)
    }

    // MARK: - Plain-value sections

    @Test func `header section renders without artwork`() {
        _ = render(DetailHeaderSection(media: movie), height: 420)
    }

    @Test func `title section renders a movie`() {
        _ = render(DetailTitleSection(media: movie), height: 120)
    }

    /// The nil branches matter: vote average, release date, and genres are all optional
    /// on the API, and each falls back to an en dash.
    @Test func `title section renders with every optional missing`() {
        let bare = TestFixtures.mediaDetail(
            releaseDate: nil,
            posterPath: nil,
            backdropPath: nil
        )
        _ = render(DetailTitleSection(media: bare), height: 120)
    }

    /// Every metadata segment populated at once — the case that pushed the old
    /// single-row layout into truncating both the date and the genres.
    @Test func `title section renders every metadata segment`() {
        let dense = TestFixtures.mediaDetail(
            title: "Toy Story 5",
            posterPath: nil,
            backdropPath: nil,
            runtime: 100,
            genres: ["Animação", "Família", "Comédia"],
            certification: "10"
        )
        _ = render(DetailTitleSection(media: dense), height: 120)
    }

    /// A series formats its runtime per episode rather than as a whole.
    @Test func `title section renders a per-episode runtime`() {
        let show = TestFixtures.tvDetail(episodeRunTime: [45])
        _ = render(DetailTitleSection(media: show), height: 120)
    }

    @Test func `synopsis section renders`() {
        _ = render(DetailSynopsisSection(media: movie), height: 200)
    }

    @Test(arguments: [0, 1, 8])
    func `cast section renders any number of members`(count: Int) {
        let cast = (0..<count).map { TestFixtures.castMember(id: $0, name: "Actor \($0)") }
        _ = render(DetailCastSection(cast: cast), height: 220)
    }

    @Test func `where to watch renders when the payload has no providers`() {
        _ = render(DetailWhereToWatchSection(media: movie, viewModel: makeVM()), height: 200)
    }

    @Test func `where to watch renders the provider strip`() {
        let withProviders = TestFixtures.mediaDetail(
            posterPath: nil,
            backdropPath: nil,
            flatrateProviders: ["Netflix", "Disney"]
        )
        _ = render(DetailWhereToWatchSection(media: withProviders, viewModel: makeVM()), height: 200)
    }

    @Test func `streaming badge renders`() {
        _ = render(StreamingBadgeView(provider: TestFixtures.streamingProvider()), width: 80, height: 80)
    }

    // MARK: - RatingStarsView

    @Test(arguments: [0.0, 2.5, 3.0, 5.0])
    func `rating stars render at every value`(value: Double) {
        rasterize(RatingStarsView(value: value), width: 200, height: 60)
    }

    @Test func `rating stars render with a rate handler`() {
        rasterize(RatingStarsView(value: 3, onRate: { _ in }), width: 200, height: 60)
    }

    // MARK: - ShareCardView

    /// Fixed 1080x1920 canvas, takes a `UIImage?` rather than a URL — the one component
    /// here with no network dependency at all.
    @Test func `share card renders without a poster`() {
        _ = render(
            ShareCardView(posterImage: nil, title: "Fight Club", starValue: 4.5),
            width: 1080,
            height: 1920
        )
    }

    @Test func `share card renders with a poster`() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 60)).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 60))
        }
        _ = render(
            ShareCardView(posterImage: image, title: "Fight Club", starValue: 4.5),
            width: 1080,
            height: 1920
        )
    }

    // MARK: - ViewModel-backed sections

    @Test(arguments: [MediaType.movie, MediaType.tv])
    func `watchlist section renders for either media type`(type: MediaType) {
        _ = render(DetailWatchlistSection(viewModel: makeVM(), mediaType: type), height: 200)
    }

    @Test(arguments: [MediaType.movie, MediaType.tv])
    func `rating section renders for either media type`(type: MediaType) {
        _ = render(DetailRatingSection(viewModel: makeVM(), mediaType: type), height: 260)
    }

    @Test func `seasons section renders`() {
        let seasons = [TestFixtures.season(seasonNumber: 1), TestFixtures.season(seasonNumber: 2)]
        _ = render(DetailSeasonsSection(seasons: seasons, viewModel: makeVM()), height: 300)
    }

    @Test func `seasons section renders with no seasons`() {
        _ = render(DetailSeasonsSection(seasons: [], viewModel: makeVM()), height: 300)
    }

    @Test func `season header renders`() {
        _ = render(
            SeasonHeaderView(season: TestFixtures.season(seasonNumber: 1), viewModel: makeVM()),
            height: 120
        )
    }

    /// `SeasonContentView` renders nothing until the view model has episodes for that
    /// season, so all three of its states have to be set up explicitly.
    @Test func `season content renders nothing before episodes load`() {
        _ = render(
            SeasonContentView(season: TestFixtures.season(seasonNumber: 1), viewModel: makeVM()),
            height: 400
        )
    }

    @Test func `season content renders its loading state`() async {
        let service = MockMediaDetailService()
        let vm = makeVM(type: .tv, id: 2, service: service)
        service.duringSeasonFetch = {
            _ = render(SeasonContentView(season: TestFixtures.season(seasonNumber: 1), viewModel: vm), height: 400)
        }
        await vm.loadSeasonIfNeeded(1)
    }

    @Test func `season content renders its failed state`() async {
        let service = MockMediaDetailService()
        service.fetchSeasonDetailResult = .failure(MockError.generic("offline"))
        let vm = makeVM(type: .tv, id: 2, service: service)
        await vm.loadSeasonIfNeeded(1)
        _ = render(SeasonContentView(season: TestFixtures.season(seasonNumber: 1), viewModel: vm), height: 400)
    }

    @Test(arguments: [false, true])
    func `season content renders loaded episodes`(allWatched: Bool) async {
        let episodes = (1...3).map { TestFixtures.episode(id: $0, episodeNumber: $0) }
        let vm = await tvVM(
            MockMediaDetailService(),
            episodes: episodes,
            watched: allWatched ? [1, 2, 3] : []
        )
        _ = render(SeasonContentView(season: TestFixtures.season(seasonNumber: 1), viewModel: vm), height: 600)
    }

    @Test(arguments: [0, 1, 6])
    func `episode list renders any number of episodes`(count: Int) {
        let episodes = (1...max(count, 1)).prefix(count).map {
            TestFixtures.episode(episodeNumber: $0)
        }
        _ = render(
            EpisodeListView(episodes: Array(episodes), seasonNumber: 1, viewModel: makeVM()),
            height: 500
        )
    }

    // MARK: - Cast and trailer

    @Test func `cast section renders members with and without a character name`() {
        let cast = TestFixtures.mediaDetail(
            cast: [(name: "Bob Odenkirk", character: "Jimmy McGill"), (name: "Rhea Seehorn", character: nil)]
        ).credits!.cast
        _ = render(DetailCastSection(cast: cast), height: 160)
    }

    /// When no member has a character name the cards drop the second line entirely
    /// instead of every one reserving an empty row.
    @Test func `cast section renders when no member has a character name`() {
        let cast = TestFixtures.mediaDetail(
            cast: [(name: "Bob Odenkirk", character: nil), (name: "Rhea Seehorn", character: "")]
        ).credits!.cast
        _ = render(DetailCastSection(cast: cast), height: 160)
    }

    /// The section caps the carousel at 20 — this is the branch that does the trimming.
    @Test func `cast section caps a very long billing list`() {
        let cast = TestFixtures.mediaDetail(
            cast: (1...30).map { (name: "Actor \($0)", character: "Role \($0)") }
        ).credits!.cast
        _ = render(DetailCastSection(cast: cast), height: 160)
    }

    @Test func `trailer button renders`() {
        let media = TestFixtures.mediaDetail(trailerKey: "abc123")
        _ = render(DetailTrailerButton(trailer: media.trailer!, viewModel: makeVM()), height: 80)
    }

    // MARK: - Person page

    @Test func `person credit card renders with and without a role`() {
        let person = TestFixtures.person(credits: [
            (id: 438631, mediaType: .movie, title: "Dune", character: "Duke Leto Atreides"),
            (id: 60059, mediaType: .tv, title: "Better Call Saul", character: nil)
        ])
        for credit in person.credits {
            _ = render(PersonCreditCard(credit: credit), height: 220)
        }
    }

    /// The cast carousel now pushes a `PersonView`, so its cards build a `NavigationLink`
    /// and need a `NavigationStack` around them to render.
    @Test func `cast section renders inside a navigation stack`() {
        let cast = TestFixtures.mediaDetail(
            cast: [(name: "Oscar Isaac", character: "Duke Leto Atreides")]
        ).credits!.cast
        _ = render(NavigationStack { DetailCastSection(cast: cast) }, height: 220)
    }

    // MARK: - In-flight states

    @Test func `episode list renders a row whose mark request is in flight`() async {
        let service = MockMediaDetailService()
        let episodes = (1...3).map { TestFixtures.episode(id: $0, episodeNumber: $0) }
        let vm = await tvVM(service, episodes: episodes)

        service.duringCall = {
            _ = render(
                EpisodeListView(episodes: episodes, seasonNumber: 1, viewModel: vm),
                height: 500
            )
        }
        await vm.toggleEpisodeWatched(season: 1, episode: 2)
    }

    @Test func `season content renders a mark-all request in flight`() async {
        let service = MockMediaDetailService()
        let vm = await tvVM(service, episodes: [TestFixtures.episode(episodeNumber: 1)])

        service.duringCall = {
            _ = render(SeasonContentView(season: TestFixtures.season(seasonNumber: 1), viewModel: vm), height: 400)
        }
        await vm.toggleSeasonWatched(1)
    }

    @Test func `rating section renders while the rating is being saved`() async {
        let service = MockMediaDetailService()
        let vm = makeVM(service: service)

        service.duringCall = {
            _ = render(DetailRatingSection(viewModel: vm, mediaType: .movie), height: 120)
        }
        await vm.rateMedia(rating: 8)
    }

    @Test(arguments: [MediaType.movie, .tv])
    func `watchlist section renders while a status change is in flight`(mediaType: MediaType) async {
        let watchlist = MockWatchlistService()
        let store = WatchlistStore()
        store.replace(with: [TestFixtures.watchItem(id: 42, tmdbId: 1, mediaType: mediaType, status: .watching)])
        let vm = makeVM(type: mediaType, watchlistService: watchlist, store: store)
        await vm.checkWatchlistStatus()

        watchlist.duringRemove = {
            _ = render(DetailWatchlistSection(viewModel: vm, mediaType: mediaType), height: 80)
        }
        await vm.removeFromWatchlist()
    }

    // MARK: - ShareSheet

    /// A `UIViewControllerRepresentable`. Its context cannot be constructed directly, so
    /// hosting it is the only way to reach `makeUIViewController`.
    @Test func `share sheet hosts its activity controller`() {
        _ = render(ShareSheet(items: ["text"]), height: 400)
    }
}
