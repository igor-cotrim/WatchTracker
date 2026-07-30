import SwiftUI
import Testing
@testable import WatchTracker

/// Renders every component in `Features/Detail/Components/`. All 15 were at 0% coverage.
///
/// The sections that take a `MediaDetailViewModel` get a real one wired to mocks, so no
/// request leaves the process. `render(_:)` does not appear the view, so none of the
/// `.task` bodies run either — see `RenderHostTests`.
@MainActor
@Suite("Detail components render", .tags(.view, .pure))
struct DetailComponentRenderTests {

    private func makeVM() -> MediaDetailViewModel {
        MediaDetailViewModel(
            mediaDetailService: MockMediaDetailService(),
            watchlistService: MockWatchlistService(),
            store: WatchlistStore()
        )
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
        _ = render(DetailWhereToWatchSection(media: movie), height: 200)
    }

    @Test func `where to watch renders the provider strip`() {
        let withProviders = TestFixtures.mediaDetail(
            posterPath: nil,
            backdropPath: nil,
            flatrateProviders: ["Netflix", "Disney"]
        )
        _ = render(DetailWhereToWatchSection(media: withProviders), height: 200)
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

    @Test func `season content renders its loading state`() {
        let vm = makeVM()
        vm.isLoadingSeason = [1]
        _ = render(SeasonContentView(season: TestFixtures.season(seasonNumber: 1), viewModel: vm), height: 400)
    }

    @Test(arguments: [false, true])
    func `season content renders loaded episodes`(allWatched: Bool) {
        let vm = makeVM()
        vm.seasonEpisodes[1] = (1...3).map {
            TestFixtures.episode(id: $0, episodeNumber: $0, isWatched: allWatched)
        }
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

    // MARK: - ShareSheet

    /// A `UIViewControllerRepresentable`. Its context cannot be constructed directly, so
    /// hosting it is the only way to reach `makeUIViewController`.
    @Test func `share sheet hosts its activity controller`() {
        _ = render(ShareSheet(items: ["text"]), height: 400)
    }
}
