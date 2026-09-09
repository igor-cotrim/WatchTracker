import Foundation
@testable import WatchTracker

/// An `AppContainer` wired to the mocks, with its own `UserDefaults` suite and its own
/// router and cache — so screens built from it never share state across tests the way
/// a single static container would.
///
/// Every collaborator is exposed so a test can configure the mock it cares about and
/// still hand the container to a view.
@MainActor
final class TestContainer {
    let analytics = MockAnalytics()
    let notifications = MockNotificationScheduler()
    let watchlist = MockWatchlistService()
    let discover = MockDiscoverService()
    let mediaDetail = MockMediaDetailService()
    let profile = MockProfileService()
    let exportData = MockExportService()
    let importData = MockImportService()
    let auth: MockAuthService
    let store = WatchlistStore()
    let outbox = MutationOutbox()
    let network = PreviewNetworkMonitor()
    let defaults: UserDefaults
    let container: AppContainer

    private let suiteName: String

    /// `auth` is optional rather than defaulted: building a `@MainActor` mock inside a
    /// default argument is a nonisolated call, which the compiler rejects.
    init(auth: MockAuthService? = nil) {
        self.auth = auth ?? MockAuthService()
        suiteName = "test-container-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        container = AppContainer(
            auth: self.auth,
            router: AppRouter(analytics: analytics),
            network: network,
            analytics: analytics,
            notifications: notifications,
            store: store,
            outbox: outbox,
            defaults: defaults,
            watchlist: watchlist,
            discover: discover,
            mediaDetail: mediaDetail,
            profile: profile,
            exportData: exportData,
            importData: importData
        )
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }
}
