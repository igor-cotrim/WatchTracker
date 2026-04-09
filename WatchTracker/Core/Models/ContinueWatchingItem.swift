import Foundation

struct ContinueWatchingItem: Codable, Identifiable {
    let id: Int
    let tmdbId: Int
    let title: String
    let posterPath: String?
    let isAnime: Bool
    let nextEpisode: NextEpisode?

    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)")
    }

    var stillURL: URL? {
        guard let stillPath = nextEpisode?.stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(stillPath)")
    }
}

struct NextEpisode: Codable {
    let seasonNumber: Int
    let episodeNumber: Int
    let name: String
    let stillPath: String?
    let airDate: String?

    var displayLabel: String {
        "T\(seasonNumber) E\(episodeNumber) · \(name)"
    }
}
