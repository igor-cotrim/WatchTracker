import Foundation

/// The browse half of Discover: the five generic rows, the provider strip, and the four
/// rows that replace them once a provider is picked.
///
/// Search lives in `SearchViewModel`. The two shared nothing but a screen — and an
/// `isLoading` that only ever described search — so changing one no longer touches the other.
@Observable
@MainActor
final class DiscoverBrowseViewModel {
    private(set) var trending: FeedState = .loading
    private(set) var nowPlaying: FeedState = .loading
    private(set) var popular: FeedState = .loading
    private(set) var topRated: FeedState = .loading
    private(set) var upcoming: FeedState = .loading

    private(set) var providers: [StreamingProvider] = []

    /// Written only by `selectProvider(_:)`, which also debounces the fetch, persists the
    /// choice and reports the analytics event — none of which a direct assignment would do.
    private(set) var selectedProvider: StreamingProvider?
    private(set) var providerRows: [ProviderRow: FeedState] = [:]

    /// Exposed so tests can await the debounced work instead of sleeping.
    private(set) var providerTask: Task<Void, Never>?

    private let service: any DiscoverServiceProtocol
    private let analytics: any AnalyticsTracking
    private let defaults: UserDefaults
    private let clock: any Clock<Duration>
    private let now: @Sendable () -> Date
    private let lastProviderKey = "discover.lastProviderId"

    init(
        service: any DiscoverServiceProtocol,
        analytics: any AnalyticsTracking,
        userDefaults: UserDefaults = .standard,
        clock: any Clock<Duration> = ContinuousClock(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.service = service
        self.analytics = analytics
        self.defaults = userDefaults
        self.clock = clock
        self.now = now
    }

    // MARK: - Loading

    /// Everything the screen needs on first appearance, in parallel.
    func load() async {
        async let t: () = fetchTrending()
        async let n: () = fetchNowPlaying()
        async let p: () = fetchPopular()
        async let r: () = fetchTopRated()
        async let u: () = fetchUpcoming()
        async let pr: () = fetchProviders()
        _ = await (t, n, p, r, u, pr)
        restoreLastProviderIfNeeded()
    }

    func fetchTrending() async {
        await load(into: \.trending) { try await self.service.fetchTrending(page: nil) }
    }

    func fetchNowPlaying() async {
        await load(into: \.nowPlaying) { try await self.service.fetchNowPlaying(page: nil) }
    }

    func fetchPopular() async {
        await load(into: \.popular) { try await self.service.fetchPopular(type: .movie, page: nil) }
    }

    func fetchTopRated() async {
        await load(into: \.topRated) { try await self.service.fetchTopRated(type: .movie, page: nil) }
    }

    func fetchUpcoming() async {
        await load(into: \.upcoming) { try await self.service.fetchUpcoming(page: nil) }
    }

    /// The provider strip is a filter control, not a content row: an empty list simply
    /// hides it, so a failure here has no error state of its own.
    func fetchProviders() async {
        providers = (try? await service.fetchProviders(type: .movie)) ?? []
    }

    // MARK: - Provider selection

    func restoreLastProviderIfNeeded() {
        guard selectedProvider == nil else { return }
        guard let storedId = defaults.object(forKey: lastProviderKey) as? Int,
              let provider = providers.first(where: { $0.providerId == storedId }) else { return }
        selectProvider(provider)
    }

    func selectProvider(_ provider: StreamingProvider?) {
        guard provider?.providerId != selectedProvider?.providerId else { return }

        providerTask?.cancel()
        selectedProvider = provider

        guard let provider else {
            defaults.removeObject(forKey: lastProviderKey)
            providerRows = [:]
            return
        }

        defaults.set(provider.providerId, forKey: lastProviderKey)
        analytics.capture(.discoverProviderFilter, properties: [
            "provider_id": provider.providerId,
            "provider_name": provider.providerName
        ])

        providerRows = Dictionary(uniqueKeysWithValues: ProviderRow.allCases.map { ($0, FeedState.loading) })
        providerTask = Task { [weak self, clock] in
            // Debounced: tapping across the strip should only fetch the row you land on.
            try? await clock.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.loadProviderRows(for: provider)
        }
    }

    private func loadProviderRows(for provider: StreamingProvider) async {
        let since = thirtyDaysAgoString()
        await withTaskGroup(of: Void.self) { group in
            for row in ProviderRow.allCases {
                group.addTask { await self.loadRow(row, provider: provider, since: since) }
            }
        }
    }

    /// One row, landing in its own slot. Guarded on the provider still being selected so a
    /// slow response for the previous provider can't overwrite the current one's row.
    private func loadRow(_ row: ProviderRow, provider: StreamingProvider, since: String) async {
        do {
            let items = try await row.load(provider: provider, since: since, using: service)
            guard isStillSelected(provider) else { return }
            providerRows[row] = .loaded(items)
        } catch {
            guard isStillSelected(provider), !(error is CancellationError) else { return }
            providerRows[row] = .failed(error.userFacingMessage)
        }
    }

    private func isStillSelected(_ provider: StreamingProvider) -> Bool {
        !Task.isCancelled && selectedProvider?.providerId == provider.providerId
    }

    /// The cutoff for the "new on <provider>" row. Uses the injected `now` so tests
    /// don't drift with the wall clock.
    func thirtyDaysAgoString() -> String {
        let today = now()
        let date = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    // MARK: - Private

    private func load(
        into keyPath: ReferenceWritableKeyPath<DiscoverBrowseViewModel, FeedState>,
        _ operation: () async throws -> [MediaDetail]
    ) async {
        do {
            let items = try await operation()
            guard !Task.isCancelled else { return }
            self[keyPath: keyPath] = .loaded(items)
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            self[keyPath: keyPath] = .failed(error.userFacingMessage)
        }
    }
}
