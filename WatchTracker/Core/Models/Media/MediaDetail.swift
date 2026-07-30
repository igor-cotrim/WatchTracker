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
    let runtime: Int?              // movies — total length in minutes
    let episodeRunTime: [Int]?     // TV — typical episode length in minutes
    let credits: Credits?
    let watchProviders: WatchProviderResult?
    let seasons: [Season]?   // TV only
    let watchlistStatus: WatchlistStatus?  // Present when authenticated and show is in watchlist
    let certification: String?  // Content rating for the request locale's region (e.g. "12", "PG-13")
    let userRating: Int?  // The caller's own rating (1–10 scale), present when authenticated and rated

    var mediaType: MediaType {
        title != nil ? .movie : .tv
    }

    /// The user's rating expressed on the 5-star / half-star scale (0.5…5.0).
    /// Backend stores 1–10 integers; each half-star is one point.
    var userStarRating: Double? {
        userRating.map { Double($0) / 2 }
    }

    var displayTitle: String {
        title ?? name ?? "Unknown"
    }

    /// Length in minutes: the whole film for a movie, one typical episode for a series.
    /// TMDB reports 0 or an empty array for titles it has no runtime for, which we
    /// treat as absent so the UI can drop the segment instead of showing "0min".
    var runtimeMinutes: Int? {
        let value = mediaType == .movie ? runtime : episodeRunTime?.first
        guard let value, value > 0 else { return nil }
        return value
    }

    var releaseYear: String? {
        let date = releaseDate ?? firstAirDate
        guard let date, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }

    var releaseDateFormatted: String? {
        let raw = releaseDate ?? firstAirDate
        guard let raw else { return releaseYear }
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: raw) else { return releaseYear }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .none
        return display.string(from: date)
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
    let link: String?
    let flatrate: [StreamingProvider]?
    let rent: [StreamingProvider]?
    let buy: [StreamingProvider]?
}
