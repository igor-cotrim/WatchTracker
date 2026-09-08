import Testing
import Foundation
@testable import WatchTracker

@MainActor
@Suite("DiscoverBrowseViewModel", .tags(.viewModel), .timeLimit(.minutes(1)))
struct DiscoverBrowseViewModelTests {

    /// Own `UserDefaults` suite per view model, and a clock that never sleeps so the
    /// provider debounce runs instantly.
    private final class Harness {
        let service = MockDiscoverService()
        let analytics = MockAnalytics()
        let clock = ImmediateClock()
        let defaults: UserDefaults
        let viewModel: DiscoverBrowseViewModel
        private let suiteName: String

        init(now: @escaping @Sendable () -> Date = Date.init) {
            suiteName = "test-\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suiteName)!
            viewModel = DiscoverBrowseViewModel(
                service: service,
                analytics: analytics,
                userDefaults: defaults,
                clock: clock,
                now: now
            )
        }

        deinit { defaults.removePersistentDomain(forName: suiteName) }
    }

    private func makeHarness(now: @escaping @Sendable () -> Date = Date.init) -> Harness {
        Harness(now: now)
    }

    // MARK: - Generic rows

    @Test func `every row starts out loading`() {
        let harness = makeHarness()
        #expect(harness.viewModel.trending.isLoading)
        #expect(harness.viewModel.nowPlaying.isLoading)
        #expect(harness.viewModel.popular.isLoading)
        #expect(harness.viewModel.topRated.isLoading)
        #expect(harness.viewModel.upcoming.isLoading)
    }

    @Test func `fetchTrending loads the row`() async {
        let harness = makeHarness()
        harness.service.fetchTrendingResult = .success([TestFixtures.mediaDetail(id: 1), TestFixtures.mediaDetail(id: 2)])

        await harness.viewModel.fetchTrending()

        #expect(harness.viewModel.trending.items.count == 2)
        #expect(harness.viewModel.trending.errorMessage == nil)
    }

    /// The point of giving each row its own state: one failure is scoped to one row
    /// instead of tripping a screen-wide `errorMessage` that any of the eleven could set.
    @Test func `a failing row fails alone`() async {
        let harness = makeHarness()
        harness.service.fetchTrendingResult = .failure(MockError.generic("error"))
        harness.service.fetchNowPlayingResult = .success([TestFixtures.mediaDetail()])

        await harness.viewModel.fetchTrending()
        await harness.viewModel.fetchNowPlaying()

        #expect(harness.viewModel.trending.errorMessage != nil)
        #expect(harness.viewModel.nowPlaying.items.count == 1)
        #expect(harness.viewModel.nowPlaying.errorMessage == nil)
    }

    @Test func `load fills every generic row`() async {
        let harness = makeHarness()
        harness.service.fetchTrendingResult = .success([TestFixtures.mediaDetail()])
        harness.service.fetchNowPlayingResult = .success([TestFixtures.mediaDetail()])
        harness.service.fetchPopularResult = .success([TestFixtures.mediaDetail()])
        harness.service.fetchTopRatedResult = .success([TestFixtures.mediaDetail()])
        harness.service.fetchUpcomingResult = .success([TestFixtures.mediaDetail()])

        await harness.viewModel.load()

        #expect(harness.viewModel.trending.items.count == 1)
        #expect(harness.viewModel.nowPlaying.items.count == 1)
        #expect(harness.viewModel.popular.items.count == 1)
        #expect(harness.viewModel.topRated.items.count == 1)
        #expect(harness.viewModel.upcoming.items.count == 1)
    }

    /// The provider strip is a control, not content: it simply doesn't appear when the
    /// request fails, so there is no error state to report.
    @Test func `a failed provider list is empty rather than an error`() async {
        let harness = makeHarness()
        harness.service.fetchProvidersResult = .failure(MockError.generic("boom"))

        await harness.viewModel.fetchProviders()

        #expect(harness.viewModel.providers.isEmpty)
    }

    // MARK: - Provider selection

    @Test func `selectProvider persists the choice and captures analytics`() async {
        let harness = makeHarness()
        let netflix = TestFixtures.streamingProvider(providerId: 8, providerName: "Netflix")

        harness.viewModel.selectProvider(netflix)
        await harness.viewModel.providerTask?.value

        #expect(harness.viewModel.selectedProvider?.providerId == 8)
        #expect(harness.defaults.object(forKey: "discover.lastProviderId") as? Int == 8)

        let properties = harness.analytics.properties(for: .discoverProviderFilter)
        #expect(properties?["provider_id"] as? Int == 8)
        #expect(properties?["provider_name"] as? String == "Netflix")
    }

    @Test func `selectProvider debounces by 300ms`() async {
        let harness = makeHarness()

        harness.viewModel.selectProvider(TestFixtures.streamingProvider(providerId: 8))
        await harness.viewModel.providerTask?.value

        #expect(harness.clock.sleeps == [.milliseconds(300)])
    }

    @Test func `selecting the same provider twice is a no-op`() async {
        let harness = makeHarness()
        let netflix = TestFixtures.streamingProvider(providerId: 8)

        harness.viewModel.selectProvider(netflix)
        await harness.viewModel.providerTask?.value
        harness.viewModel.selectProvider(netflix)

        #expect(harness.analytics.capturedEvents.filter { $0 == .discoverProviderFilter }.count == 1)
    }

    @Test func `selectProvider loads all four rows`() async {
        let harness = makeHarness()
        harness.service.discoverFilteredResult = .success([TestFixtures.mediaDetail()])

        harness.viewModel.selectProvider(TestFixtures.streamingProvider(providerId: 8))
        await harness.viewModel.providerTask?.value

        for row in ProviderRow.allCases {
            #expect(harness.viewModel.providerRows[row]?.items.isEmpty == false, "\(row) should have loaded")
        }
    }

    @Test func `deselecting clears persisted state and the provider rows`() async {
        let harness = makeHarness()
        harness.service.discoverFilteredResult = .success([TestFixtures.mediaDetail()])
        harness.viewModel.selectProvider(TestFixtures.streamingProvider(providerId: 8))
        await harness.viewModel.providerTask?.value

        harness.viewModel.selectProvider(nil)

        #expect(harness.viewModel.selectedProvider == nil)
        #expect(harness.viewModel.providerRows.isEmpty)
        #expect(harness.defaults.object(forKey: "discover.lastProviderId") == nil)
    }

    @Test func `restoreLastProviderIfNeeded reselects the persisted provider`() async {
        let harness = makeHarness()
        harness.defaults.set(8, forKey: "discover.lastProviderId")
        harness.service.fetchProvidersResult = .success([TestFixtures.streamingProvider(providerId: 8)])
        await harness.viewModel.fetchProviders()

        harness.viewModel.restoreLastProviderIfNeeded()
        await harness.viewModel.providerTask?.value

        #expect(harness.viewModel.selectedProvider?.providerId == 8)
    }

    @Test func `restoreLastProviderIfNeeded ignores a provider that is no longer offered`() async {
        let harness = makeHarness()
        harness.defaults.set(999, forKey: "discover.lastProviderId")
        harness.service.fetchProvidersResult = .success([TestFixtures.streamingProvider(providerId: 8)])
        await harness.viewModel.fetchProviders()

        harness.viewModel.restoreLastProviderIfNeeded()

        #expect(harness.viewModel.selectedProvider == nil)
    }

    @Test func `restoreLastProviderIfNeeded does nothing when a provider is already selected`() async {
        let harness = makeHarness()
        harness.service.fetchProvidersResult = .success([
            TestFixtures.streamingProvider(providerId: 8),
            TestFixtures.streamingProvider(providerId: 337)
        ])
        await harness.viewModel.fetchProviders()
        harness.viewModel.selectProvider(TestFixtures.streamingProvider(providerId: 8))
        await harness.viewModel.providerTask?.value

        harness.defaults.set(337, forKey: "discover.lastProviderId")
        harness.viewModel.restoreLastProviderIfNeeded()

        #expect(harness.viewModel.selectedProvider?.providerId == 8)
    }

    // MARK: - Date window

    @Test func `thirtyDaysAgoString formats the window start in UTC`() {
        let fixed = Date(timeIntervalSince1970: 1_768_478_400)  // 2026-01-15T12:00:00Z
        let harness = makeHarness(now: { fixed })
        #expect(harness.viewModel.thirtyDaysAgoString() == "2025-12-16")
    }
}
