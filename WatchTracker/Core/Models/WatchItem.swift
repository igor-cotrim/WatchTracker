import Foundation

struct WatchItem: Codable, Identifiable {
    let id: Int
    let userId: String
    let tmdbId: Int
    let mediaType: MediaType
    let status: WatchlistStatus
    let addedAt: Date

    // Display fields populated from TMDB data
    var title: String?
    var posterPath: String?
    var newEpisodesCount: Int?

    /// Full URL for the TMDB poster image.
    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)")
    }
}
