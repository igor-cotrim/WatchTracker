import Foundation

// Encodable payloads for the mutating endpoints in `Endpoint`.

struct AddToWatchlistBody: Encodable, Sendable {
    let tmdbId: Int
    let mediaType: MediaType
    let status: WatchlistStatus
}

struct RateMediaBody: Encodable, Sendable {
    let rating: Int
}

struct UpdateWatchlistStatusBody: Encodable, Sendable {
    let status: WatchlistStatus
}

struct ImportBody: Encodable, Sendable {
    let source: String
    let items: [ImportItem]
}
