import Foundation

/// The filter sheet: the draft the user is building, plus the genre and provider lists
/// it offers.
///
/// The draft is `private(set)` like every other observable in the app — a chip tap goes
/// through the method named for it, because switching the media type is not an assignment:
/// it reloads the genre list and drops genres that only exist for the other type.
@Observable
@MainActor
final class DiscoverFilterViewModel {
    private(set) var draft: DiscoverFilter
    private(set) var genres: [Genre] = []
    private(set) var providers: [StreamingProvider] = []
    private(set) var isLoadingGenres = false

    /// Exposed so tests can await the genre reload a type change kicks off.
    private(set) var genresTask: Task<Void, Never>?

    private let service: any DiscoverServiceProtocol
    private let analytics: any AnalyticsTracking

    init(
        initialFilter: DiscoverFilter = DiscoverFilter(),
        service: any DiscoverServiceProtocol,
        analytics: any AnalyticsTracking
    ) {
        self.draft = initialFilter
        self.service = service
        self.analytics = analytics
    }

    // MARK: - Loading

    func load() async {
        async let genres: () = loadGenres(for: draft.type.mediaType)
        async let providers: () = loadProviders()
        _ = await (genres, providers)
    }

    /// A failure leaves the list empty, which hides that section rather than blocking the
    /// sheet: the other criteria still work, and the user came here to filter, not to read
    /// an error.
    private func loadGenres(for type: MediaType) async {
        isLoadingGenres = true
        defer { isLoadingGenres = false }
        let loaded = (try? await service.fetchGenres(type: type)) ?? []
        guard !Task.isCancelled, draft.type.mediaType == type else { return }
        genres = loaded
    }

    private func loadProviders() async {
        providers = (try? await service.fetchProviders(type: .movie)) ?? []
    }

    // MARK: - User actions

    /// Genre ids do not carry across TMDB types, so switching between movie and series
    /// drops the selection rather than silently querying with ids that mean something else.
    /// Series and anime share a TMDB type, so that switch keeps both the list and the picks.
    func selectType(_ type: DiscoverType) {
        guard type != draft.type else { return }
        let previousMediaType = draft.type.mediaType
        draft.type = type
        guard type.mediaType != previousMediaType else { return }

        draft.genreIds = []
        genres = []
        genresTask?.cancel()
        genresTask = Task { [weak self, mediaType = type.mediaType] in
            await self?.loadGenres(for: mediaType)
        }
    }

    func toggleGenre(_ id: Int) {
        if draft.genreIds.contains(id) {
            draft.genreIds.remove(id)
        } else {
            draft.genreIds.insert(id)
        }
    }

    func toggleProvider(_ id: Int) {
        if draft.providerIds.contains(id) {
            draft.providerIds.remove(id)
        } else {
            draft.providerIds.insert(id)
        }
    }

    func selectSort(_ sort: DiscoverSort) {
        draft.sort = sort
    }

    func selectReleaseWindow(_ window: ReleaseWindow) {
        draft.releaseWindow = window
    }

    /// Resets everything but the type: clearing back to "no type" is not a state the filter
    /// has, and dropping it would also throw away the loaded genre list.
    func clearAll() {
        draft = DiscoverFilter(type: draft.type)
    }

    /// Called when the user commits the draft. Returns it so the caller can navigate to
    /// the results without reaching into the view model for state it already has.
    func apply() -> DiscoverFilter {
        analytics.capture(.discoverFilterApplied, properties: [
            "type": draft.type.rawValue,
            "genre_count": draft.genreIds.count,
            "provider_count": draft.providerIds.count,
            "sort": draft.sort.rawValue,
            "release_window": draft.releaseWindow.rawValue
        ])
        return draft
    }
}
