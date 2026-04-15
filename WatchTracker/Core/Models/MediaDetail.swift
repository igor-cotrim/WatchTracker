import Foundation

struct MediaDetail: Codable, Identifiable {
    let id: Int
    let title: String?       // movies
    let name: String?        // TV shows
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let firstAirDate: String?
    let genres: [Genre]?
    let credits: Credits?
    let watchProviders: WatchProviderResult?
    let seasons: [Season]?   // TV only
    let watchlistStatus: WatchlistStatus?  // Present when authenticated and show is in watchlist

    var mediaType: MediaType {
        title != nil ? .movie : .tv
    }

    var displayTitle: String {
        title ?? name ?? "Unknown"
    }

    var releaseYear: String? {
        let date = releaseDate ?? firstAirDate
        guard let date, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }

    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)")
    }

    var backdropURL: URL? {
        guard let backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(backdropPath)")
    }
}

struct Genre: Codable, Identifiable {
    let id: Int
    let name: String
}

struct Credits: Codable {
    let cast: [CastMember]
}

struct CastMember: Codable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?

    var profileURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}

struct WatchProviderResult: Codable {
    let results: [String: WatchProviderRegion]?
}

struct WatchProviderRegion: Codable {
    let flatrate: [StreamingProvider]?
    let rent: [StreamingProvider]?
    let buy: [StreamingProvider]?
}
