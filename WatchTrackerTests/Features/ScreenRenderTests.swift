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
/// `AppRouter` is injected per test rather than shared, so screens reading
/// `@Environment(AppRouter.self)` do not fight over `AppRouter.shared`.
@MainActor
@Suite("Screens render", .tags(.view, .pure))
struct ScreenRenderTests {

    private let suiteName = "ScreenRenderTests"

    private func watchlistVM(items: [WatchItem] = []) -> WatchlistViewModel {
        let store = WatchlistStore()
        store.cachedItems = items
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
        _ = render(HomeView())
    }

    @Test(arguments: MediaFilter.allCases)
    func `watchlist screen renders each filter`(filter: MediaFilter) {
        _ = render(
            WatchlistView(viewModel: watchlistVM(items: items), filter: filter)
                .environment(AppRouter())
        )
    }

    /// The empty state is a different branch from the populated one, and it is what a
    /// brand new account sees.
    @Test(arguments: MediaFilter.allCases)
    func `watchlist screen renders its empty state`(filter: MediaFilter) {
        _ = render(
            WatchlistView(viewModel: watchlistVM(), filter: filter)
                .environment(AppRouter())
        )
    }

    // MARK: - Discover

    @Test func `discover screen renders`() {
        _ = render(DiscoverView())
    }

    @Test func `browse grid screen renders`() {
        let vm = BrowseGridViewModel { _ in [] }
        _ = render(BrowseGridView(viewModel: vm))
    }

    @Test func `mood browse screen renders`() {
        guard let mood = MoodPreset.all.first else { return }
        _ = render(MoodBrowseView(mood: mood))
    }

    // MARK: - Watching

    @Test func `watching screen renders`() {
        _ = render(WatchingView().environment(AppRouter()))
    }

    // MARK: - Detail

    @Test(arguments: [MediaType.movie, MediaType.tv])
    func `media detail screen renders`(type: MediaType) {
        _ = render(MediaDetailView(mediaType: type, mediaId: 550))
    }

    // MARK: - Profile

    @Test func `profile screen renders`() {
        defer { tearDown() }
        _ = render(ProfileView(auth: MockAuthService(currentUser: AuthFixtures.user())))
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
        _ = render(DataView())
    }

    // MARK: - App shell

    @Test func `tab shell renders`() {
        _ = render(
            AppTabView()
                .environment(AppRouter())
                .environment(AuthService(client: MockSupabaseAuthClient()))
        )
    }

    @Test func `splash screen renders`() {
        _ = render(SplashView())
    }
}
