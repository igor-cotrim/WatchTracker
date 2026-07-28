import Foundation

struct ImportItem: Encodable, Sendable, Equatable {
    let title: String
    let year: Int?
    /// Raw status string rather than `WatchlistStatus`, for the same reason as
    /// `ExportEntry.status`: the backend also stores `dropped`, which the enum
    /// has no case for, and a round trip must not silently drop it.
    let status: String?
    let rating: Int?
    let watchedDate: String?
    /// Set only when the row came from a WatchTracker export. It lets the backend
    /// skip the TMDB search and treat `status` as authoritative.
    let tmdbId: Int?
    let mediaType: MediaType?

    init(
        title: String,
        year: Int? = nil,
        status: String? = nil,
        rating: Int? = nil,
        watchedDate: String? = nil,
        tmdbId: Int? = nil,
        mediaType: MediaType? = nil,
    ) {
        self.title = title
        self.year = year
        self.status = status
        self.rating = rating
        self.watchedDate = watchedDate
        self.tmdbId = tmdbId
        self.mediaType = mediaType
    }
}

/// One watched episode, already resolved to a show id — no TMDB lookup needed.
struct ImportEpisode: Encodable, Sendable, Equatable {
    let tmdbId: Int
    let seasonNumber: Int
    let episodeNumber: Int
    let watchedDate: String?
}

/// Everything a set of picked files yielded, ready to upload.
struct ImportBatch: Sendable, Equatable {
    var items: [ImportItem] = []
    var episodes: [ImportEpisode] = []

    var isEmpty: Bool { items.isEmpty && episodes.isEmpty }

    /// Which export this batch came from. Anything carrying TMDB ids can only
    /// have come from our own export; the backend validates the value.
    var source: String {
        items.contains { $0.tmdbId != nil } || !episodes.isEmpty ? "watchtracker" : "letterboxd"
    }
}

struct ImportBatchResult: Decodable, Sendable {
    struct Counts: Decodable, Sendable {
        let watchlist: Int
        let ratings: Int
        let episodes: Int
    }

    struct UnmatchedItem: Decodable, Sendable {
        let title: String
        let year: Int?
    }

    let total: Int
    let matched: Int
    let imported: Counts
    let unmatched: [UnmatchedItem]
}
