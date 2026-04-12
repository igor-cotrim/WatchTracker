import Foundation

struct UpcomingItem: Codable, Identifiable {
    let tmdbId: Int
    let title: String
    let posterPath: String?
    let isAnime: Bool
    let nextEpisode: UpcomingEpisode
    let watchProviders: [String]

    var id: Int { tmdbId }

    var posterURL: URL? {
        guard let p = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(p)")
    }
}

struct UpcomingEpisode: Codable {
    let seasonNumber: Int
    let episodeNumber: Int
    let name: String
    let airDate: String
    let daysUntilAir: Int
    let stillPath: String?

    var stillURL: URL? {
        guard let p = stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(p)")
    }
}
