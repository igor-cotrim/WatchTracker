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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    /// Parsed `airDate`, used for release checks and sorting.
    var airDateValue: Date? {
        guard let airDate else { return nil }
        return Self.dateFormatter.date(from: airDate)
    }

    /// `true` if the episode has already aired or the air date is unknown.
    var isReleased: Bool {
        guard let date = airDateValue else { return true }
        let today = Calendar.current.startOfDay(for: Date())
        let airDay = Calendar.current.startOfDay(for: date)
        return airDay <= today
    }
}
