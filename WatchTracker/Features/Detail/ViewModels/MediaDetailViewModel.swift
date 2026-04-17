import Foundation
import SwiftUI

@Observable
@MainActor
final class MediaDetailViewModel {
    var media: MediaDetail?
    var isLoading = false
    var userRating: Int?
    var errorMessage: String?

    // Watchlist state
    var isOnWatchlist = false
    var isCheckingStatus = false
    var watchlistItemId: Int?
    var watchlistStatus: WatchlistStatus?
    private var hasLoadedInitialStatus = false

    // Season expansion
    var expandedSeasons: Set<Int> = []
    var seasonEpisodes: [Int: [Episode]] = [:]
    var isLoadingSeason: Set<Int> = []

    private var mediaType: MediaType = .movie
    private var mediaId: Int = 0
    private let mediaDetailService: MediaDetailServiceProtocol
    private let watchlistService: WatchlistServiceProtocol
    private let store: WatchlistStore

    init(
        mediaDetailService: MediaDetailServiceProtocol,
        watchlistService: WatchlistServiceProtocol,
        store: WatchlistStore
    ) {
        self.mediaDetailService = mediaDetailService
        self.watchlistService = watchlistService
        self.store = store
    }

    func fetchDetails(type: MediaType, id: Int) async {
        self.mediaType = type
        self.mediaId = id
        isLoading = true
        errorMessage = nil
        do {
            let detail = try await mediaDetailService.fetchMediaDetail(type: type, id: id)
            media = detail
            // If the backend updated the status (e.g. completed → watching due to new episodes),
            // sync it to local state without a separate watchlist fetch.
            if hasLoadedInitialStatus,
               let backendStatus = detail.watchlistStatus,
               backendStatus != watchlistStatus {
                watchlistStatus = backendStatus
                store.needsRefresh = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func checkWatchlistStatus() async {
        isCheckingStatus = true
        defer {
            isCheckingStatus = false
            hasLoadedInitialStatus = true
        }

        // Read from in-memory cache — no network call needed.
        let cachedItems = store.cachedItems
        if let item = cachedItems.first(where: { $0.tmdbId == mediaId && $0.mediaType == mediaType }) {
            isOnWatchlist = true
            watchlistItemId = item.id
            watchlistStatus = item.status
        } else {
            isOnWatchlist = false
            watchlistItemId = nil
            watchlistStatus = nil
        }
    }

    func addToWatchlist(status: WatchlistStatus) async {
        do {
            try await watchlistService.addToWatchlist(tmdbId: mediaId, mediaType: mediaType, status: status)
            if status == .completed && mediaType == .tv {
                try? await watchlistService.markAllEpisodesWatched(tvId: mediaId)
                for seasonNumber in seasonEpisodes.keys {
                    seasonEpisodes[seasonNumber] = seasonEpisodes[seasonNumber]?.map { ep in
                        var updated = ep
                        updated.isWatched = true
                        return updated
                    }
                }
            }
            // Refresh the store cache so other screens (Home) see the change immediately.
            await refreshStoreCache()
            // Read back from the updated cache to get the server-assigned id.
            syncLocalStateFromCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFromWatchlist() async {
        guard let itemId = watchlistItemId else { return }
        do {
            try await watchlistService.removeFromWatchlist(id: itemId)
            isOnWatchlist = false
            watchlistItemId = nil
            watchlistStatus = nil
            // Refresh the store cache so Home sees the change immediately.
            await refreshStoreCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

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
        guard seasonEpisodes[seasonNumber] == nil else { return }
        isLoadingSeason.insert(seasonNumber)
        do {
            let season = try await mediaDetailService.fetchSeasonDetail(tvId: mediaId, season: seasonNumber)
            let watchedNumbers = (try? await mediaDetailService.fetchWatchedEpisodes(tvId: mediaId, season: seasonNumber)) ?? []
            let watchedSet = Set(watchedNumbers)
            let episodes = (season.episodes ?? []).map { ep in
                var e = ep
                e.isWatched = watchedSet.contains(ep.episodeNumber)
                return e
            }
            seasonEpisodes[seasonNumber] = episodes
            isLoadingSeason.remove(seasonNumber)
        } catch {
            errorMessage = error.localizedDescription
            isLoadingSeason.remove(seasonNumber)
        }
    }

    func rateMedia(rating: Int) async {
        do {
            try await mediaDetailService.rateMedia(type: mediaType, id: mediaId, rating: rating)
            userRating = rating
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleEpisodeWatched(season: Int, episode: Int) async {
        guard mediaType == .tv else { return }

        let isCurrentlyWatched = seasonEpisodes[season]?
            .first(where: { $0.episodeNumber == episode })?.isWatched ?? false

        do {
            let statusChanged: WatchlistStatus?
            if isCurrentlyWatched {
                statusChanged = try await mediaDetailService.unmarkEpisodeWatched(tvId: mediaId, season: season, episode: episode)
            } else {
                statusChanged = try await mediaDetailService.markEpisodeWatched(tvId: mediaId, season: season, episode: episode)
            }
            // Flip local state
            if var episodes = seasonEpisodes[season],
               let index = episodes.firstIndex(where: { $0.episodeNumber == episode }) {
                episodes[index].isWatched = !isCurrentlyWatched
                seasonEpisodes[season] = episodes
            }
            await applyStatusChange(statusChanged)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSeasonWatched(_ seasonNumber: Int) async {
        guard mediaType == .tv else { return }

        let allWatched = seasonEpisodes[seasonNumber]?.allSatisfy(\.isWatched) ?? false

        do {
            let statusChanged: WatchlistStatus?
            if allWatched {
                statusChanged = try await mediaDetailService.unmarkSeasonWatched(tvId: mediaId, season: seasonNumber)
                seasonEpisodes[seasonNumber] = seasonEpisodes[seasonNumber]?.map { ep in
                    var e = ep
                    e.isWatched = false
                    return e
                }
            } else {
                statusChanged = try await mediaDetailService.markSeasonWatched(tvId: mediaId, season: seasonNumber)
                seasonEpisodes[seasonNumber] = seasonEpisodes[seasonNumber]?.map { ep in
                    var e = ep
                    e.isWatched = true
                    return e
                }
            }
            await applyStatusChange(statusChanged)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyStatusChange(_ newStatus: WatchlistStatus?) async {
        guard let newStatus, newStatus != watchlistStatus else { return }
        watchlistStatus = newStatus
        isOnWatchlist = true
        // Refresh cache to get the server-assigned watchlistItemId and propagate to Home.
        await refreshStoreCache()
        syncLocalStateFromCache()
    }

    // MARK: - Cache Helpers

    /// Fetches the full watchlist from the API, updates the shared store cache,
    /// and clears the `needsRefresh` flag so Home won't refetch redundantly.
    private func refreshStoreCache() async {
        do {
            let items = try await watchlistService.fetchWatchlist(status: nil, mediaType: nil)
            store.cachedItems = items
            store.needsRefresh = false
        } catch {
            // If the refresh fails, mark dirty so Home retries later.
            store.needsRefresh = true
        }
    }

    /// Reads the current media's watchlist entry from the shared cache and
    /// updates this ViewModel's local state (id, status, isOnWatchlist).
    private func syncLocalStateFromCache() {
        let cachedItems = store.cachedItems
        if let item = cachedItems.first(where: { $0.tmdbId == mediaId && $0.mediaType == mediaType }) {
            isOnWatchlist = true
            watchlistItemId = item.id
            watchlistStatus = item.status
        } else {
            isOnWatchlist = false
            watchlistItemId = nil
            watchlistStatus = nil
        }
    }

    // MARK: - Helpers

    func isSeasonAllWatched(_ seasonNumber: Int) -> Bool {
        guard let episodes = seasonEpisodes[seasonNumber], !episodes.isEmpty else { return false }
        return episodes.allSatisfy(\.isWatched)
    }

    var displayStatus: String {
        watchlistStatus?.displayName ?? "Na Lista"
    }
}
