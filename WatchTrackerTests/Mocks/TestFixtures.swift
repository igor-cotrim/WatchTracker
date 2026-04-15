import Foundation
@testable import WatchTracker

// MARK: - Fixture helpers

private let fixtureDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    d.dateDecodingStrategy = .iso8601
    return d
}()

private func dateString(daysFromToday offset: Int) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
    return fmt.string(from: date)
}

// MARK: - TestFixtures

enum TestFixtures {

    // MARK: WatchItem

    static func watchItem(
        id: Int = 1,
        tmdbId: Int = 100,
        mediaType: MediaType = .movie,
        status: WatchlistStatus = .planToWatch,
        isAnime: Bool? = nil
    ) -> WatchItem {
        let animeValue = isAnime.map { $0 ? "true" : "false" } ?? "null"
        let json = """
        {
            "id": \(id),
            "user_id": "test-user",
            "tmdb_id": \(tmdbId),
            "media_type": "\(mediaType.rawValue)",
            "status": "\(status.rawValue)",
            "added_at": "2026-01-01T00:00:00Z",
            "title": "Test Title",
            "poster_path": "/test.jpg",
            "new_episodes_count": null,
            "is_anime": \(animeValue)
        }
        """
        return try! fixtureDecoder.decode(WatchItem.self, from: Data(json.utf8))
    }

    // MARK: MediaDetail

    static func mediaDetail(
        id: Int = 1,
        title: String? = "Test Movie",
        name: String? = nil,
        watchlistStatus: WatchlistStatus? = nil
    ) -> MediaDetail {
        let titleValue = title.map { "\"\($0)\"" } ?? "null"
        let nameValue = name.map { "\"\($0)\"" } ?? "null"
        let statusValue = watchlistStatus.map { "\"\($0.rawValue)\"" } ?? "null"
        let json = """
        {
            "id": \(id),
            "title": \(titleValue),
            "name": \(nameValue),
            "overview": "Test overview",
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
            "vote_average": 8.0,
            "release_date": "2020-01-15",
            "first_air_date": null,
            "genres": null,
            "credits": null,
            "watch_providers": null,
            "seasons": null,
            "watchlist_status": \(statusValue)
        }
        """
        return try! fixtureDecoder.decode(MediaDetail.self, from: Data(json.utf8))
    }

    static func tvDetail(
        id: Int = 2,
        name: String = "Test Show",
        watchlistStatus: WatchlistStatus? = nil
    ) -> MediaDetail {
        mediaDetail(id: id, title: nil, name: name, watchlistStatus: watchlistStatus)
    }

    // MARK: UpcomingEpisode

    /// Creates an `UpcomingEpisode` via JSON decode so the private `daysUntilAir` is set.
    /// `localDaysUntilAir` is computed from `airDate` — pass a date string relative to today.
    static func upcomingEpisode(
        airDate: String,
        fallbackDays: Int = 0,
        seasonNumber: Int = 1,
        episodeNumber: Int = 1,
        name: String = "Test Episode",
        stillPath: String? = nil
    ) -> UpcomingEpisode {
        let stillValue = stillPath.map { "\"\($0)\"" } ?? "null"
        let json = """
        {
            "season_number": \(seasonNumber),
            "episode_number": \(episodeNumber),
            "name": "\(name)",
            "air_date": "\(airDate)",
            "still_path": \(stillValue),
            "days_until_air": \(fallbackDays)
        }
        """
        return try! fixtureDecoder.decode(UpcomingEpisode.self, from: Data(json.utf8))
    }

    static func upcomingEpisodeDaysFromToday(_ offset: Int) -> UpcomingEpisode {
        upcomingEpisode(airDate: dateString(daysFromToday: offset), fallbackDays: offset)
    }

    // MARK: UpcomingItem

    static func upcomingItem(
        tmdbId: Int = 1,
        title: String = "Test Show",
        isAnime: Bool = false,
        nextEpisodeDaysFromToday offset: Int = 1,
        watchProviders: [String] = []
    ) -> UpcomingItem {
        let episode = upcomingEpisodeDaysFromToday(offset)
        let airDate = dateString(daysFromToday: offset)
        let providersJSON = watchProviders.map { "\"\($0)\"" }.joined(separator: ", ")
        let json = """
        {
            "tmdb_id": \(tmdbId),
            "title": "\(title)",
            "poster_path": null,
            "is_anime": \(isAnime ? "true" : "false"),
            "next_episode": {
                "season_number": \(episode.seasonNumber),
                "episode_number": \(episode.episodeNumber),
                "name": "\(episode.name)",
                "air_date": "\(airDate)",
                "still_path": null,
                "days_until_air": \(offset)
            },
            "watch_providers": [\(providersJSON)]
        }
        """
        return try! fixtureDecoder.decode(UpcomingItem.self, from: Data(json.utf8))
    }

    // MARK: NextEpisode

    static func nextEpisode(
        seasonNumber: Int = 1,
        episodeNumber: Int = 1,
        name: String = "Test Episode",
        airDate: String? = nil,
        stillPath: String? = nil
    ) -> NextEpisode {
        let airDateValue = airDate.map { "\"\($0)\"" } ?? "null"
        let stillValue = stillPath.map { "\"\($0)\"" } ?? "null"
        let json = """
        {
            "season_number": \(seasonNumber),
            "episode_number": \(episodeNumber),
            "name": "\(name)",
            "still_path": \(stillValue),
            "air_date": \(airDateValue)
        }
        """
        return try! fixtureDecoder.decode(NextEpisode.self, from: Data(json.utf8))
    }

    // MARK: ContinueWatchingItem

    static func continueWatchingItem(
        id: Int = 1,
        tmdbId: Int = 100,
        title: String = "Test Show",
        nextEpisode: NextEpisode? = nil,
        isAnime: Bool = false
    ) -> ContinueWatchingItem {
        let nextEpisodeJSON: String
        if let ep = nextEpisode {
            let airDateValue = ep.airDate.map { "\"\($0)\"" } ?? "null"
            let stillValue = ep.stillPath.map { "\"\($0)\"" } ?? "null"
            nextEpisodeJSON = """
            {
                "season_number": \(ep.seasonNumber),
                "episode_number": \(ep.episodeNumber),
                "name": "\(ep.name)",
                "still_path": \(stillValue),
                "air_date": \(airDateValue)
            }
            """
        } else {
            nextEpisodeJSON = "null"
        }
        let json = """
        {
            "id": \(id),
            "tmdb_id": \(tmdbId),
            "title": "\(title)",
            "poster_path": null,
            "is_anime": \(isAnime ? "true" : "false"),
            "next_episode": \(nextEpisodeJSON)
        }
        """
        return try! fixtureDecoder.decode(ContinueWatchingItem.self, from: Data(json.utf8))
    }

    // MARK: Episode

    static func episode(
        id: Int = 1,
        name: String = "Test Episode",
        episodeNumber: Int = 1,
        seasonNumber: Int = 1,
        isWatched: Bool = false,
        stillPath: String? = nil
    ) -> Episode {
        let stillValue = stillPath.map { "\"\($0)\"" } ?? "null"
        let json = """
        {
            "id": \(id),
            "name": "\(name)",
            "overview": null,
            "episode_number": \(episodeNumber),
            "season_number": \(seasonNumber),
            "still_path": \(stillValue),
            "air_date": null
        }
        """
        var ep = try! fixtureDecoder.decode(Episode.self, from: Data(json.utf8))
        ep.isWatched = isWatched
        return ep
    }

    // MARK: Season

    static func season(
        id: Int = 1,
        name: String = "Season 1",
        seasonNumber: Int = 1,
        episodes: [Episode]? = nil
    ) -> Season {
        Season(
            id: id,
            name: name,
            seasonNumber: seasonNumber,
            episodeCount: episodes?.count,
            posterPath: nil,
            airDate: nil,
            episodes: episodes
        )
    }

    // MARK: Date helpers

    static func todayDateString() -> String { dateString(daysFromToday: 0) }
    static func tomorrowDateString() -> String { dateString(daysFromToday: 1) }
    static func yesterdayDateString() -> String { dateString(daysFromToday: -1) }
}
