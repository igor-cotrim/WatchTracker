import Foundation
import SwiftUI

private struct WatchedEpisodesResponse: Decodable {
    let watchedEpisodes: [Int]
}

private struct EpisodeStatusResponse: Decodable {
    let statusChanged: WatchlistStatus?
}

private struct SeasonStatusResponse: Decodable {
    let message: String
    let statusChanged: WatchlistStatus?
}

private struct WatchAllStatusResponse: Decodable {
    let markedCount: Int
    let statusChanged: WatchlistStatus?
}

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

    // Season expansion
    var expandedSeasons: Set<Int> = []
    var seasonEpisodes: [Int: [Episode]] = [:]
    var isLoadingSeason: Set<Int> = []

    private var mediaType: MediaType = .movie
    private var mediaId: Int = 0
    private let api = APIClient.shared
    private let watchlistService = WatchlistService()

    func fetchDetails(type: MediaType, id: Int) async {
        self.mediaType = type
        self.mediaId = id
        isLoading = true
        errorMessage = nil
        do {
            let detail: MediaDetail = try await api.get(.mediaDetail(type: type, id: id))
            media = detail
            // If the backend updated the status (e.g. completed → watching due to new episodes),
            // sync it to local state without a separate watchlist fetch.
            if let backendStatus = detail.watchlistStatus, backendStatus != watchlistStatus {
                watchlistStatus = backendStatus
                WatchlistStore.shared.needsRefresh = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func checkWatchlistStatus() async {
        isCheckingStatus = true
        defer { isCheckingStatus = false }
        do {
            let items = try await watchlistService.fetchWatchlist()
            if let item = items.first(where: { $0.tmdbId == mediaId && $0.mediaType == mediaType }) {
                isOnWatchlist = true
                watchlistItemId = item.id
                watchlistStatus = item.status
            } else {
                isOnWatchlist = false
                watchlistItemId = nil
                watchlistStatus = nil
            }
        } catch {
            // Silently fail — watchlist status is non-critical
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
            WatchlistStore.shared.needsRefresh = true
            await checkWatchlistStatus()
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
            WatchlistStore.shared.needsRefresh = true
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
            let season: Season = try await api.get(.seasonDetail(tvId: mediaId, season: seasonNumber))
            let watched: WatchedEpisodesResponse? = try? await api.get(.watchedEpisodes(tvId: mediaId, season: seasonNumber))
            let watchedSet = Set(watched?.watchedEpisodes ?? [])
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
            try await api.post(.rateMedia(type: mediaType, id: mediaId, rating: rating))
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
            if isCurrentlyWatched {
                let response: SeasonStatusResponse = try await api.delete(.unwatchEpisode(tvId: mediaId, season: season, episode: episode))
                applyStatusChange(response.statusChanged)
            } else {
                let response: EpisodeStatusResponse = try await api.post(.watchEpisode(tvId: mediaId, season: season, episode: episode))
                applyStatusChange(response.statusChanged)
            }
            // Flip local state
            if var episodes = seasonEpisodes[season],
               let index = episodes.firstIndex(where: { $0.episodeNumber == episode }) {
                episodes[index].isWatched = !isCurrentlyWatched
                seasonEpisodes[season] = episodes
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSeasonWatched(_ seasonNumber: Int) async {
        guard mediaType == .tv else { return }

        let allWatched = seasonEpisodes[seasonNumber]?.allSatisfy(\.isWatched) ?? false

        do {
            if allWatched {
                let response: SeasonStatusResponse = try await api.delete(.unwatchSeason(tvId: mediaId, season: seasonNumber))
                applyStatusChange(response.statusChanged)
                seasonEpisodes[seasonNumber] = seasonEpisodes[seasonNumber]?.map { ep in
                    var e = ep
                    e.isWatched = false
                    return e
                }
            } else {
                let response: SeasonStatusResponse = try await api.post(.watchSeason(tvId: mediaId, season: seasonNumber))
                applyStatusChange(response.statusChanged)
                seasonEpisodes[seasonNumber] = seasonEpisodes[seasonNumber]?.map { ep in
                    var e = ep
                    e.isWatched = true
                    return e
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyStatusChange(_ newStatus: WatchlistStatus?) {
        guard let newStatus, newStatus != watchlistStatus else { return }
        watchlistStatus = newStatus
        WatchlistStore.shared.needsRefresh = true
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
