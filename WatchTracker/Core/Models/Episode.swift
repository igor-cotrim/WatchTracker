import Foundation

struct Episode: Codable, Identifiable {
    let id: Int
    let name: String
    let overview: String?
    let episodeNumber: Int
    let seasonNumber: Int
    let stillPath: String?
    let airDate: String?
    var isWatched: Bool = false  // local state

    enum CodingKeys: String, CodingKey {
        case id, name, overview, episodeNumber, seasonNumber, stillPath, airDate
    }

    var stillURL: URL? {
        guard let stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(stillPath)")
    }
}

struct Season: Codable, Identifiable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int?
    let posterPath: String?
    let airDate: String?
    var episodes: [Episode]?

    enum CodingKeys: String, CodingKey {
        case id, name, seasonNumber, episodeCount, posterPath, airDate, episodes
    }

    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(posterPath)")
    }
}
