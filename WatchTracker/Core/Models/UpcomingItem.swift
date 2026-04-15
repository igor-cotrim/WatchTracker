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
    let stillPath: String?

    /// Backend-provided value (may be stale / UTC-based). Kept for Codable conformance.
    private let daysUntilAir: Int

    /// Locally-computed day difference using the device's calendar & timezone.
    /// TMDB `airDate` is a pure calendar date (e.g. "2026-04-15"), so we parse it
    /// without a time component and compare against today in the user's timezone.
    var localDaysUntilAir: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        guard let air = fmt.date(from: airDate) else { return daysUntilAir }
        let today = Calendar.current.startOfDay(for: Date())
        let airDay = Calendar.current.startOfDay(for: air)
        return Calendar.current.dateComponents([.day], from: today, to: airDay).day ?? daysUntilAir
    }

    var stillURL: URL? {
        guard let p = stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(p)")
    }
}
