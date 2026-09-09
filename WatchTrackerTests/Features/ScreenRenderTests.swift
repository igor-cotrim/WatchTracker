import SwiftUI
import Testing
@testable import WatchTracker

/// Renders every navigable screen. These were the last big block at 0% coverage.
///
/// Screens are only testable here because `render(_:)` evaluates `body` *without*
/// appearing the view (see `RenderHostTests`), so none of the `.task` modifiers run —
/// `DiscoverView` alone would otherwise fire six concurrent fetches, and `WatchingView`
/// would schedule real notifications. The screens that build their own view models are
/// left untouched: the services they construct are inert until a `.task` calls them.
///
/// Each test builds its own `TestContainer`, so screens get mock-backed services, an
/// isolated `UserDefaults` suite and their own `AppRouter` — there is no shared graph
/// left for two tests to fight over.
@MainActor
@Suite("Screens render", .tags(.view, .pure))
struct ScreenRenderTests {

    private let suiteName = "ScreenRenderTests"

    /// Screens read the container out of the environment (`MediaDetailView`, `PersonView`,
    /// `BrowseGridView`) as well as taking it through `init`, so every render supplies both.
    private func hosted<V: View>(_ view: V, _ test: TestContainer) -> some View {
        view
            .environment(test.container)
            .environment(test.container.router)
    }

    private func watchlistVM(items: [WatchItem] = []) -> WatchlistViewModel {
        let store = WatchlistStore()
        store.replace(with: items)
        return WatchlistViewModel(
            service: MockWatchlistService(),
            store: store,
            notifications: MockNotificationScheduler()
        )
    }

    private func profileVM() -> ProfileViewModel {
        ProfileViewModel(
            service: MockProfileService(),
            auth: MockAuthService(currentUser: AuthFixtures.user()),
            notifications: MockNotificationScheduler(),
            defaults: UserDefaults(suiteName: suiteName)!,
            canSendMail: { false }
        )
    }

    private func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    private var items: [WatchItem] {
        [
            TestFixtures.watchItem(id: 1, status: .watching, posterPath: nil),
            TestFixtures.watchItem(id: 2, mediaType: .tv, status: .completed, posterPath: nil)
        ]
    }

    // MARK: - Home

    @Test func `home screen renders`() {
        let test = TestContainer()
        _ = render(hosted(HomeView(container: test.container), test))
    }

    @Test(arguments: MediaFilter.allCases)
    func `watchlist screen renders each filter`(filter: MediaFilter) {
        _ = render(
            WatchlistView(viewModel: watchlistVM(items: items), filter: filter)
                .environment(AppRouter(analytics: MockAnalytics()))
        )
    }

    /// The empty state is a different branch from the populated one, and it is what a
    /// brand new account sees.
    @Test(arguments: MediaFilter.allCases)
    func `watchlist screen renders its empty state`(filter: MediaFilter) {
        _ = render(
            WatchlistView(viewModel: watchlistVM(), filter: filter)
                .environment(AppRouter(analytics: MockAnalytics()))
        )
    }

    // MARK: - Discover

    @Test func `discover screen renders`() {
        let test = TestContainer()
        _ = render(hosted(DiscoverView(container: test.container), test))
    }

    @Test func `browse grid screen renders`() {
        let test = TestContainer()
        _ = render(hosted(BrowseGridView(feed: .trending), test))
    }

    @Test func `mood browse screen renders`() {
        guard let mood = MoodPreset.all.first else { return }
        let test = TestContainer()
        _ = render(hosted(MoodBrowseView(mood: mood), test))
    }

    // MARK: - Watching

    @Test func `watching screen renders`() {
        let test = TestContainer()
        _ = render(hosted(WatchingView(container: test.container), test))
    }

    // MARK: - Detail

    @Test(arguments: [MediaType.movie, MediaType.tv])
    func `media detail screen renders`(type: MediaType) {
        let test = TestContainer()
        _ = render(hosted(MediaDetailView(mediaType: type, mediaId: 550), test))
    }

    @Test func `person screen renders`() {
        let test = TestContainer()
        _ = render(hosted(PersonView(personId: 25072, personName: "Oscar Isaac"), test))
    }

    /// The loaded state, which the bare screen render never reaches: `render(_:)` does not
    /// appear the view, so `PersonView`'s `.task` never runs and its body stays on the
    /// spinner branch. Injecting a primed ViewModel is what exercises the real layout.
    @Test func `person screen renders a loaded filmography`() async {
        let service = MockMediaDetailService()
        service.fetchPersonResult = .success(TestFixtures.person(
            credits: [
                (id: 438631, mediaType: .movie, title: "Duna", character: "Duke Leto Atreides"),
                (id: 60059, mediaType: .tv, title: "Cavaleiro da Lua", character: nil)
            ]
        ))
        let viewModel = PersonViewModel(service: service, analytics: MockAnalytics())
        await viewModel.load(id: 25072)

        let test = TestContainer()
        _ = render(hosted(NavigationStack {
            PersonView(personId: 25072, personName: "Oscar Isaac", viewModel: viewModel)
        }, test))
    }

    @Test func `person screen renders someone with no biography and no credits`() async {
        let service = MockMediaDetailService()
        service.fetchPersonResult = .success(TestFixtures.person(biography: nil, credits: []))
        let viewModel = PersonViewModel(service: service, analytics: MockAnalytics())
        await viewModel.load(id: 1)

        let test = TestContainer()
        _ = render(hosted(NavigationStack {
            PersonView(personId: 1, personName: "Nobody", viewModel: viewModel)
        }, test))
    }

    // MARK: - Profile

    @Test func `profile screen renders`() {
        let test = TestContainer(auth: MockAuthService(currentUser: AuthFixtures.user()))
        _ = render(hosted(ProfileView(container: test.container), test))
    }

    @Test func `stats screen renders`() {
        defer { tearDown() }
        _ = render(StatsView(viewModel: profileVM()))
    }

    // MARK: - Auth

    @Test func `auth screen renders`() {
        _ = render(AuthView(auth: MockAuthService()))
    }

    @Test func `forgot password screen renders`() {
        _ = render(ForgotPasswordView(auth: MockAuthService()))
    }

    @Test func `forgot password screen renders with a prefilled email`() {
        _ = render(ForgotPasswordView(auth: MockAuthService(), prefillEmail: "user@example.com"))
    }

    // MARK: - Data

    @Test func `data screen renders`() {
        let test = TestContainer()
        _ = render(hosted(DataView(container: test.container), test))
    }

    // MARK: - App shell

    @Test func `tab shell renders`() {
        let test = TestContainer()
        _ = render(hosted(AppTabView(), test))
    }

    @Test func `splash screen renders`() {
        _ = render(SplashView())
    }
}
