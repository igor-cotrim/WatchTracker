import Foundation

@Observable
@MainActor
final class MediaDetailViewModel {

    // MARK: - Screen state

    private(set) var state: MediaDetailState = .idle
    private(set) var recommendations: [MediaDetail] = []
    private(set) var userRating: Int?

    // MARK: - Watchlist

    private(set) var entry: WatchlistEntry?
    private(set) var isCheckingStatus = false
    private(set) var isUpdatingStatus = false
    private var hasLoadedInitialStatus = false

    // MARK: - Seasons

    private(set) var seasons: [Int: SeasonState] = [:]
    private(set) var expandedSeasons: Set<Int> = []
    /// Season the view should scroll to, set when the show is marked as "watching".
    /// The view clears it through `didScrollToSeason()` once the scroll has happened.
    private(set) var scrollTargetSeason: Int?

    // MARK: - In-flight writes

    /// Every mark/unmark is a round trip, so the row, the season pill and the stars each
    /// need to show that the tap landed and lock out a second tap before the server answers.
    /// These are genuinely concurrent with each other and with the screen load, which is why
    /// they stay separate flags rather than collapsing into `state`.
    private(set) var pendingEpisodes: Set<EpisodeRef> = []
    private(set) var pendingSeasons: Set<Int> = []
    private(set) var isSubmittingRating = false

    /// A write that failed. Kept apart from `state` and from the season states: a rating or
    /// a mark that did not land must not blank out the title the user is looking at, which
    /// is what a single screen-wide `errorMessage` sink could not distinguish.
    private(set) var actionError: String?

    // MARK: - Share card

    private(set) var isRenderingShare = false
    private(set) var shareItem: ShareableImage?

    /// Identifies one episode within the currently-open show.
    struct EpisodeRef: Hashable {
        let season: Int
        let episode: Int
    }

    let mediaType: MediaType
    let mediaId: Int

    private let mediaDetailService: MediaDetailServiceProtocol
    private let watchlistService: WatchlistServiceProtocol
    private let store: WatchlistStore
    private let analytics: any AnalyticsTracking

    /// The title is identity, not a call argument: every method here is about *this* one,
    /// so it is fixed at construction rather than assigned by whichever fetch ran first.
    init(
        mediaType: MediaType,
        mediaId: Int,
        mediaDetailService: MediaDetailServiceProtocol,
        watchlistService: WatchlistServiceProtocol,
        store: WatchlistStore,
        analytics: any AnalyticsTracking
    ) {
        self.mediaType = mediaType
        self.mediaId = mediaId
        self.mediaDetailService = mediaDetailService
        self.watchlistService = watchlistService
        self.store = store
        self.analytics = analytics
    }

    // MARK: - Derived reads for the view

    var media: MediaDetail? { state.media }
    var isOnWatchlist: Bool { entry != nil }
    var watchlistStatus: WatchlistStatus? { entry?.status }

    func episodes(inSeason seasonNumber: Int) -> [Episode] {
        seasons[seasonNumber]?.episodes ?? []
    }

    func seasonState(_ seasonNumber: Int) -> SeasonState? {
        seasons[seasonNumber]
    }

    func isEpisodePending(season: Int, episode: Int) -> Bool {
        pendingEpisodes.contains(EpisodeRef(season: season, episode: episode))
    }

    func isSeasonPending(_ seasonNumber: Int) -> Bool {
        pendingSeasons.contains(seasonNumber)
    }

    func isSeasonAllWatched(_ seasonNumber: Int) -> Bool {
        let episodes = episodes(inSeason: seasonNumber)
        return !episodes.isEmpty && episodes.allSatisfy(\.isWatched)
    }

    // MARK: - Loading

    /// Everything the screen opens with: the title, its recommendations and the user's
    /// watchlist row, in that dependency order.
    func load() async {
        async let details: () = fetchDetails()
        async let recs: () = fetchRecommendations()
        _ = await (details, recs)
        await checkWatchlistStatus()
    }

    func fetchDetails() async {
        state = .loading
        do {
            let detail = try await mediaDetailService.fetchMediaDetail(type: mediaType, id: mediaId)
            state = .loaded(detail)
            userRating = detail.userRating
            analytics.capture(.detailViewed, properties: [
                "media_type": mediaType.rawValue,
                "media_id": mediaId,
                "title": detail.displayTitle
            ])
            // If the backend updated the status (e.g. completed → watching due to new episodes),
            // sync it to local state without a separate watchlist fetch.
            if hasLoadedInitialStatus,
               let backendStatus = detail.watchlistStatus,
               let current = entry,
               backendStatus != current.status {
                entry = WatchlistEntry(id: current.id, status: backendStatus)
                store.invalidate()
            }
        } catch {
            state = .failed(error.userFacingMessage)
        }
    }

    /// Recommendations are a bonus row: a failure hides it rather than taking the screen
    /// down with it, so the error is deliberately swallowed.
    func fetchRecommendations() async {
        recommendations = (try? await mediaDetailService.fetchRecommendations(type: mediaType, id: mediaId)) ?? []
    }

    func checkWatchlistStatus() async {
        isCheckingStatus = true
        defer {
            isCheckingStatus = false
            hasLoadedInitialStatus = true
        }
        syncEntryFromCache()
    }

    // MARK: - Watchlist

    func addToWatchlist(status: WatchlistStatus) async {
        guard !isUpdatingStatus else { return }
        isUpdatingStatus = true
        defer { isUpdatingStatus = false }

        do {
            let isNewEntry = entry == nil
            if let entry {
                try await watchlistService.updateStatus(id: entry.id, status: status)
            } else {
                try await watchlistService.addToWatchlist(tmdbId: mediaId, mediaType: mediaType, status: status)
            }
            analytics.capture(
                isNewEntry ? .watchlistAdded : .watchlistStatusChanged,
                properties: [
                    "media_type": mediaType.rawValue,
                    "media_id": mediaId,
                    "status": status.rawValue
                ]
            )
            if status == .completed && mediaType == .tv {
                try? await watchlistService.markAllEpisodesWatched(tvId: mediaId)
                markEveryLoadedEpisode(watched: true)
            }
            // Refresh the store cache so other screens (Home) see the change immediately.
            await store.refresh(using: watchlistService)
            // Read back from the updated cache to get the server-assigned id.
            syncEntryFromCache()
            // When starting to watch a show, open the first not-fully-watched season
            // and scroll to it so the user can immediately mark episodes.
            if status == .watching && mediaType == .tv {
                await openFirstUnwatchedSeason()
            }
        } catch {
            actionError = error.userFacingMessage
        }
    }

    func removeFromWatchlist() async {
        guard let entry, !isUpdatingStatus else { return }
        isUpdatingStatus = true
        defer { isUpdatingStatus = false }
        do {
            try await watchlistService.removeFromWatchlist(id: entry.id)
            analytics.capture(.watchlistRemoved, properties: [
                "media_type": mediaType.rawValue,
                "media_id": mediaId
            ])
            self.entry = nil
            // Refresh the store cache so Home sees the change immediately.
            await store.refresh(using: watchlistService)
        } catch {
            actionError = error.userFacingMessage
        }
    }

    // MARK: - Seasons

    /// Synchronously toggles the expanded state. Call this inside `withAnimation` from the view.
    func toggleExpanded(_ seasonNumber: Int) {
        if expandedSeasons.contains(seasonNumber) {
            expandedSeasons.remove(seasonNumber)
        } else {
            expandedSeasons.insert(seasonNumber)
        }
    }

    /// Loads episode data for a season if not already cached.
    func loadSeasonIfNeeded(_ seasonNumber: Int) async {
        guard seasons[seasonNumber] == nil else { return }
        seasons[seasonNumber] = .loading
        do {
            let season = try await mediaDetailService.fetchSeasonDetail(tvId: mediaId, season: seasonNumber)
            let watched = Set((try? await mediaDetailService.fetchWatchedEpisodes(tvId: mediaId, season: seasonNumber)) ?? [])
            seasons[seasonNumber] = .loaded((season.episodes ?? []).map { episode in
                var episode = episode
                episode.isWatched = watched.contains(episode.episodeNumber)
                return episode
            })
        } catch {
            // Scoped to the season that failed: the rest of the screen, and the other
            // seasons, are unaffected — which the single screen-wide error could not express.
            seasons[seasonNumber] = .failed(error.userFacingMessage)
        }
    }

    /// Expands the first season that isn't fully watched (falling back to the first
    /// season) and asks the view to scroll to it. TV shows only.
    func openFirstUnwatchedSeason() async {
        guard mediaType == .tv else { return }
        let all = (media?.seasons ?? [])
            .filter { ($0.episodeCount ?? 0) > 0 }
            .sorted { $0.seasonNumber < $1.seasonNumber }
        guard let first = all.first else { return }

        var target = first.seasonNumber
        for season in all {
            await loadSeasonIfNeeded(season.seasonNumber)
            if !isSeasonAllWatched(season.seasonNumber) {
                target = season.seasonNumber
                break
            }
        }

        expandedSeasons.insert(target)
        await loadSeasonIfNeeded(target)
        scrollTargetSeason = target
    }

    func didScrollToSeason() {
        scrollTargetSeason = nil
    }

    // MARK: - Episode / season marking

    func toggleEpisodeWatched(season: Int, episode: Int) async {
        guard mediaType == .tv else { return }

        let ref = EpisodeRef(season: season, episode: episode)
        guard !pendingEpisodes.contains(ref) else { return }
        pendingEpisodes.insert(ref)
        defer { pendingEpisodes.remove(ref) }

        let isWatched = episodes(inSeason: season)
            .first { $0.episodeNumber == episode }?.isWatched ?? false

        do {
            let statusChanged = isWatched
                ? try await mediaDetailService.unmarkEpisodeWatched(tvId: mediaId, season: season, episode: episode)
                : try await mediaDetailService.markEpisodeWatched(tvId: mediaId, season: season, episode: episode)

            var updated = episodes(inSeason: season)
            if let index = updated.firstIndex(where: { $0.episodeNumber == episode }) {
                updated[index].isWatched = !isWatched
                seasons[season] = .loaded(updated)
            }
            await applyStatusChange(statusChanged)
        } catch {
            // The episode list on screen is still correct — only the write failed.
            actionError = error.userFacingMessage
        }
    }

    func toggleSeasonWatched(_ seasonNumber: Int) async {
        guard mediaType == .tv, !pendingSeasons.contains(seasonNumber) else { return }
        pendingSeasons.insert(seasonNumber)
        defer { pendingSeasons.remove(seasonNumber) }

        let allWatched = isSeasonAllWatched(seasonNumber)

        do {
            let statusChanged = allWatched
                ? try await mediaDetailService.unmarkSeasonWatched(tvId: mediaId, season: seasonNumber)
                : try await mediaDetailService.markSeasonWatched(tvId: mediaId, season: seasonNumber)

            seasons[seasonNumber] = .loaded(episodes(inSeason: seasonNumber).map { episode in
                var episode = episode
                episode.isWatched = !allWatched
                return episode
            })
            await applyStatusChange(statusChanged)
        } catch {
            actionError = error.userFacingMessage
        }
    }

    // MARK: - Rating

    func rateMedia(rating: Int) async {
        let previous = userRating
        userRating = rating
        isSubmittingRating = true
        defer { isSubmittingRating = false }
        do {
            try await mediaDetailService.rateMedia(type: mediaType, id: mediaId, rating: rating)
            analytics.capture(.mediaRated, properties: [
                "media_type": mediaType.rawValue,
                "media_id": mediaId,
                "rating": rating
            ])
        } catch {
            userRating = previous
            actionError = error.userFacingMessage
        }
    }

    func removeRating() async {
        let previous = userRating
        userRating = nil
        isSubmittingRating = true
        defer { isSubmittingRating = false }
        do {
            try await mediaDetailService.removeRating(type: mediaType, id: mediaId)
            analytics.capture(.ratingRemoved, properties: [
                "media_type": mediaType.rawValue,
                "media_id": mediaId
            ])
        } catch {
            userRating = previous
            actionError = error.userFacingMessage
        }
    }

    // MARK: - Sharing

    /// Renders the rating card. Lives here rather than in the view because it fetches the
    /// poster over the network — the one thing a `View` must never do.
    func shareRating() async {
        guard let media = state.media, let rating = userRating, !isRenderingShare else { return }
        isRenderingShare = true
        defer { isRenderingShare = false }

        let image = await ShareCardRenderer.render(
            title: media.displayTitle,
            posterPath: media.posterPath,
            starValue: Double(rating) / 2
        )
        if let image {
            shareItem = ShareableImage(image: image)
        }
    }

    func dismissShareCard() {
        shareItem = nil
    }

    func dismissActionError() {
        actionError = nil
    }

    // MARK: - Analytics the view triggers

    /// The view opens the URL — that is a view job — but the event that says which link was
    /// taken is not, so it comes back through here.
    func providerLinkTapped(_ provider: StreamingProvider, openedVia: String) {
        analytics.capture(.providerLinkTapped, properties: [
            "provider_id": provider.providerId,
            "provider_name": provider.providerName,
            "title": state.media?.displayTitle ?? "",
            "opened_via": openedVia
        ])
    }

    func trailerOpened(_ trailer: MediaTrailer, openedVia: String) {
        analytics.capture(.trailerOpened, properties: [
            "title": state.media?.displayTitle ?? "",
            "trailer_key": trailer.key,
            "site": trailer.site,
            "opened_via": openedVia
        ])
    }

    // MARK: - Private

    private func applyStatusChange(_ newStatus: WatchlistStatus?) async {
        guard let newStatus, newStatus != entry?.status else { return }
        // Refresh the cache to get the server-assigned id and propagate to Home, then read
        // the whole entry back from it rather than patching a half-known one in place.
        await store.refresh(using: watchlistService)
        syncEntryFromCache()
    }

    private func markEveryLoadedEpisode(watched: Bool) {
        for (number, state) in seasons {
            seasons[number] = .loaded(state.episodes.map { episode in
                var episode = episode
                episode.isWatched = watched
                return episode
            })
        }
    }

    /// Reads this title's watchlist row out of the shared cache.
    /// If duplicates exist (legacy data created before the DB unique constraint),
    /// picks the most recently added row so the UI reflects the latest state.
    private func syncEntryFromCache() {
        let matches = store.cachedItems.filter { $0.tmdbId == mediaId && $0.mediaType == mediaType }
        entry = matches.max { $0.id < $1.id }.map { WatchlistEntry(id: $0.id, status: $0.status) }
    }
}
