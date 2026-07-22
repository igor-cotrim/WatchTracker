import Foundation

struct ImportItem: Encodable, Sendable {
    let title: String
    let year: Int?
    let status: WatchlistStatus?
    let rating: Int?
    let watchedDate: String?
}

struct ImportBatchResult: Decodable, Sendable {
    struct Counts: Decodable, Sendable {
        let watchlist: Int
        let ratings: Int
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
