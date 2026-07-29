import Foundation

protocol MediaDetailServiceProtocol: Sendable {
    func fetchMediaDetail(type: MediaType, id: Int) async throws -> MediaDetail
    func fetchRecommendations(type: MediaType, id: Int) async throws -> [MediaDetail]
    func fetchSeasonDetail(tvId: Int, season: Int) async throws -> Season
    func fetchWatchedEpisodes(tvId: Int, season: Int) async throws -> [Int]
    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus?
    func unmarkEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus?
    func markSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus?
    func unmarkSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus?
    func rateMedia(type: MediaType, id: Int, rating: Int) async throws
    func removeRating(type: MediaType, id: Int) async throws
}

// MARK: - Private Response Types

private struct WatchedEpisodesResponse: Decodable {
    let watchedEpisodes: [Int]
}

private struct SeasonStatusResponse: Decodable {
    let message: String
    let statusChanged: WatchlistStatus?
}

// MARK: - MediaDetailService

final class MediaDetailService {
    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func fetchMediaDetail(type: MediaType, id: Int) async throws -> MediaDetail {
        try await api.get(.mediaDetail(type: type, id: id))
    }

    func fetchRecommendations(type: MediaType, id: Int) async throws -> [MediaDetail] {
        try await api.get(.mediaRecommendations(type: type, id: id))
    }

    func fetchSeasonDetail(tvId: Int, season: Int) async throws -> Season {
        try await api.get(.seasonDetail(tvId: tvId, season: season))
    }

    func fetchWatchedEpisodes(tvId: Int, season: Int) async throws -> [Int] {
        let response: WatchedEpisodesResponse = try await api.get(.watchedEpisodes(tvId: tvId, season: season))
        return response.watchedEpisodes
    }

    func markEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus? {
        let response: EpisodeWatchedResponse = try await api.post(.watchEpisode(tvId: tvId, season: season, episode: episode))
        return response.statusChanged
    }

    func unmarkEpisodeWatched(tvId: Int, season: Int, episode: Int) async throws -> WatchlistStatus? {
        let response: SeasonStatusResponse = try await api.delete(.unwatchEpisode(tvId: tvId, season: season, episode: episode))
        return response.statusChanged
    }

    func markSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus? {
        let response: SeasonStatusResponse = try await api.post(.watchSeason(tvId: tvId, season: season))
        return response.statusChanged
    }

    func unmarkSeasonWatched(tvId: Int, season: Int) async throws -> WatchlistStatus? {
        let response: SeasonStatusResponse = try await api.delete(.unwatchSeason(tvId: tvId, season: season))
        return response.statusChanged
    }

    func rateMedia(type: MediaType, id: Int, rating: Int) async throws {
        try await api.post(.rateMedia(type: type, id: id, rating: rating))
    }

    func removeRating(type: MediaType, id: Int) async throws {
        try await api.delete(.removeRating(type: type, id: id))
    }
}

extension MediaDetailService: MediaDetailServiceProtocol {}
