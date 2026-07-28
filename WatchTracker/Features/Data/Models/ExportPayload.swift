import Foundation

/// The user's whole library as returned by `GET /export`, already enriched with
/// TMDB titles and years (the backend only stores TMDB ids).
struct ExportPayload: Decodable, Sendable {
    let generatedAt: Date
    let unresolved: Int
    let items: [ExportEntry]
    let episodes: [ExportEpisode]
}

/// A watched episode. Carries only ids — the exporter joins it to `items` by
/// `tmdbId` to recover the show name.
struct ExportEpisode: Decodable, Sendable {
    let tmdbId: Int
    let seasonNumber: Int
    let episodeNumber: Int
    let watchedAt: Date?
}

struct ExportEntry: Decodable, Sendable {
    let tmdbId: Int
    let mediaType: MediaType
    let title: String
    let year: Int?
    /// Raw status string rather than `WatchlistStatus`: the backend also accepts
    /// `dropped`, which the enum has no case for, and decoding would throw on it.
    let status: String?
    /// 1–10 as stored by the backend. Letterboxd's 0.5–5 stars is `rating / 2`.
    let rating: Int?
    let addedAt: Date?
    let ratedAt: Date?
}
