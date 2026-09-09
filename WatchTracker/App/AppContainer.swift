import Foundation

/// The one place concrete dependencies are assembled.
///
/// Nothing else in the app reaches for a `.shared` — the four that remain are named here
/// and nowhere else. Services, the router, the watchlist cache and every ViewModel are
/// built here and handed to whoever needs them. Screens take
/// the container through `init(container:)` when their parent already has it, and read it
/// from the environment when they are reachable from too many call sites to thread it
/// through (`MediaDetailView`, `PersonView`, `BrowseGridView`).
///
/// `@Observable` is here only because that is the overload of `.environment(_:)` this uses —
/// every stored property is a `let`, so there is nothing to observe. It is deliberately not
/// a singleton: `AppContainer.live` is built once, in `WatchTrackerApp`, and passed down.
@MainActor
@Observable
final class AppContainer {
    let auth: any AuthServiceProtocol
    let router: AppRouter
    let startup: AppStartup
    /// Read by `AppTabView` to show the offline banner, and by the tab roots to refetch the
    /// moment a connection comes back. It carries no data, so exposing it costs nothing.
    let network: any NetworkMonitoring

    // Everything below is private: a View that could reach a service would be one edit away
    // from calling it, which is the rule this type exists to enforce.
    private let analytics: any AnalyticsTracking
    private let notifications: any NotificationScheduling
    private let store: WatchlistStore
    private let outbox: MutationOutbox
    private let searchHistory: SearchHistoryManager
    /// One `UserDefaults` for the whole graph, so a test container can hand every
    /// preference-reading view model an isolated suite instead of the shared domain.
    private let defaults: UserDefaults
    private let watchlist: any WatchlistServiceProtocol
    private let discover: any DiscoverServiceProtocol
    private let mediaDetail: any MediaDetailServiceProtocol
    private let profile: any ProfileServiceProtocol
    private let exportData: any ExportServiceProtocol
    private let importData: any ImportServiceProtocol

    init(
        auth: any AuthServiceProtocol,
        router: AppRouter,
        network: any NetworkMonitoring,
        analytics: any AnalyticsTracking,
        notifications: any NotificationScheduling,
        store: WatchlistStore,
        outbox: MutationOutbox,
        defaults: UserDefaults = .standard,
        watchlist: any WatchlistServiceProtocol,
        discover: any DiscoverServiceProtocol,
        mediaDetail: any MediaDetailServiceProtocol,
        profile: any ProfileServiceProtocol,
        exportData: any ExportServiceProtocol,
        importData: any ImportServiceProtocol
    ) {
        self.auth = auth
        self.router = router
        self.network = network
        self.analytics = analytics
        self.notifications = notifications
        self.store = store
        self.outbox = outbox
        self.defaults = defaults
        self.searchHistory = SearchHistoryManager(userDefaults: defaults)
        self.watchlist = watchlist
        self.discover = discover
        self.mediaDetail = mediaDetail
        self.profile = profile
        self.exportData = exportData
        self.importData = importData
        self.startup = AppStartup(service: watchlist, notifications: notifications)
    }

    // MARK: - Compositions

    /// The real graph. Starting analytics belongs here rather than in `WatchTrackerApp.init`:
    /// it is the one moment the concrete `AnalyticsService` is known.
    static let live: AppContainer = {
        let analytics = AnalyticsService.shared
        analytics.start()

        // Sized before the first request goes out. The default shared cache is a few
        // megabytes, which a single scroll through a poster grid evicts — and a poster the
        // cache still holds is the difference between a Home screen that looks normal
        // offline and one full of grey rectangles.
        URLCache.shared = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 512 * 1024 * 1024
        )

        let api = APIClient.shared
        let router = AppRouter(analytics: analytics)
        let store = WatchlistStore(archive: JSONFileArchive(filename: "watchlist-cache.json"))
        let outbox = MutationOutbox(archive: JSONFileArchive(filename: "pending-mutations.json"))
        let notifications = NotificationService.shared
        let watchlist = WatchlistService(api: api)

        return AppContainer(
            auth: AuthService(
                client: LiveSupabaseAuthClient(SupabaseManager.shared.client),
                api: api,
                router: router,
                store: store,
                outbox: outbox,
                notifications: notifications
            ),
            router: router,
            network: NetworkMonitor(),
            analytics: analytics,
            notifications: notifications,
            store: store,
            outbox: outbox,
            watchlist: watchlist,
            discover: DiscoverService(api: api),
            mediaDetail: MediaDetailService(api: api),
            profile: ProfileService(api: api),
            exportData: ExportService(api: api),
            importData: ImportService(api: api)
        )
    }()

    /// The offline graph every `#Preview` runs on: no backend, no keychain, no analytics.
    static let preview: AppContainer = {
        let analytics = PreviewAnalytics()
        return AppContainer(
            auth: PreviewAuthService(),
            router: AppRouter(analytics: analytics),
            network: PreviewNetworkMonitor(),
            analytics: analytics,
            notifications: PreviewNotificationScheduler(),
            store: WatchlistStore(),
            outbox: MutationOutbox(),
            defaults: UserDefaults(suiteName: "preview") ?? .standard,
            watchlist: PreviewWatchlistService(),
            discover: PreviewDiscoverService(),
            mediaDetail: PreviewMediaDetailService(),
            profile: PreviewProfileService(),
            exportData: PreviewExportService(),
            importData: PreviewImportService()
        )
    }()

    // MARK: - Pending writes

    /// `true` while there are changes the backend has not seen yet, so the offline banner can
    /// promise they are not lost.
    var hasPendingMutations: Bool { !outbox.isEmpty }

    /// Replays every write that was made without a connection, then re-reads the watchlist if
    /// any of them landed.
    ///
    /// Called from `AppTabView` when connectivity returns. It lives here rather than on the
    /// outbox because draining needs two services, and the container is the only thing that
    /// holds both.
    func syncPendingMutations() async {
        guard !outbox.isEmpty else { return }
        let result = await outbox.drain(watchlist: watchlist, mediaDetail: mediaDetail)
        guard result.changedAnything else { return }
        await store.refresh(using: watchlist)
    }

    // MARK: - ViewModel factories

    func makeWatchlistViewModel() -> WatchlistViewModel {
        WatchlistViewModel(service: watchlist, store: store, notifications: notifications)
    }

    func makeContinueWatchingViewModel() -> ContinueWatchingViewModel {
        ContinueWatchingViewModel(service: watchlist, store: store, outbox: outbox)
    }

    func makeUpcomingViewModel() -> UpcomingViewModel {
        UpcomingViewModel(service: watchlist, notifications: notifications)
    }

    func makeDiscoverBrowseViewModel() -> DiscoverBrowseViewModel {
        DiscoverBrowseViewModel(service: discover, analytics: analytics, userDefaults: defaults)
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(service: discover, historyStore: searchHistory, analytics: analytics)
    }

    func makeDiscoverFilterViewModel(initialFilter: DiscoverFilter) -> DiscoverFilterViewModel {
        DiscoverFilterViewModel(initialFilter: initialFilter, service: discover, analytics: analytics)
    }

    func makeBrowseGridViewModel(for feed: BrowseFeed) -> BrowseGridViewModel {
        BrowseGridViewModel(feed: feed, service: discover)
    }

    func makeMediaDetailViewModel(type: MediaType, id: Int) -> MediaDetailViewModel {
        MediaDetailViewModel(
            mediaType: type,
            mediaId: id,
            mediaDetailService: mediaDetail,
            watchlistService: watchlist,
            store: store,
            outbox: outbox,
            analytics: analytics
        )
    }

    func makePersonViewModel() -> PersonViewModel {
        PersonViewModel(service: mediaDetail, analytics: analytics)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(service: profile, auth: auth, notifications: notifications, defaults: defaults)
    }

    func makeExportViewModel() -> ExportViewModel {
        ExportViewModel(service: exportData, analytics: analytics)
    }

    func makeImportViewModel() -> ImportViewModel {
        ImportViewModel(service: importData)
    }

    @available(iOS 26, *)
    func makeAISuggestionsViewModel() -> AISuggestionsViewModel {
        AISuggestionsViewModel(
            aiService: AIService(discoverService: discover),
            watchlistService: watchlist,
            store: store
        )
    }
}
