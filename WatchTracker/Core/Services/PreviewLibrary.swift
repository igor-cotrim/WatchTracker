import Foundation

/// The fixed catalogue the `Preview…Service` doubles serve.
///
/// Values are decoded from JSON rather than built with memberwise initialisers because
/// several models keep stored properties private (`UpcomingEpisode.daysUntilAir`) or
/// rename keys — decoding is the only way to populate them from outside their file, and
/// it reuses `APIClient.makeDecoder()` so the shapes stay honest to what the backend sends.
enum PreviewLibrary {

    static let movie: MediaDetail = decode(
        """
        {
          "id": 550,
          "title": "Fight Club",
          "overview": "A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.",
          "poster_path": "/preview-poster.jpg",
          "backdrop_path": "/preview-backdrop.jpg",
          "vote_average": 8.4,
          "release_date": "1999-10-15",
          "runtime": 139,
          "genres": [{ "id": 18, "name": "Drama" }],
          "certification": "18",
          "user_rating": 9,
          "credits": {
            "cast": [
              { "id": 819, "name": "Edward Norton", "character": "The Narrator", "profile_path": "/preview-face.jpg" },
              { "id": 287, "name": "Brad Pitt", "character": "Tyler Durden", "profile_path": null }
            ]
          },
          "trailer": { "key": "SUXWAEX2jlg", "name": "Trailer", "site": "YouTube" }
        }
        """
    )

    static let show: MediaDetail = decode(
        """
        {
          "id": 1396,
          "name": "Breaking Bad",
          "overview": "A high school chemistry teacher turned methamphetamine producer.",
          "poster_path": "/preview-poster.jpg",
          "backdrop_path": "/preview-backdrop.jpg",
          "vote_average": 8.9,
          "first_air_date": "2008-01-20",
          "episode_run_time": [49],
          "genres": [{ "id": 18, "name": "Drama" }],
          "watchlist_status": "watching",
          "seasons": [
            { "id": 3572, "name": "Temporada 1", "season_number": 1, "episode_count": 7, "poster_path": "/preview-poster.jpg", "air_date": "2008-01-20" },
            { "id": 3573, "name": "Temporada 2", "season_number": 2, "episode_count": 13, "poster_path": "/preview-poster.jpg", "air_date": "2009-03-08" }
          ]
        }
        """
    )

    static let catalogue: [MediaDetail] = [movie, show, movie, show, movie, show]

    static let season: Season = decode(
        """
        {
          "id": 3572,
          "name": "Temporada 1",
          "season_number": 1,
          "episode_count": 3,
          "poster_path": "/preview-poster.jpg",
          "air_date": "2008-01-20",
          "episodes": [
            { "id": 62085, "name": "Pilot", "overview": "The one that starts it all.", "episode_number": 1, "season_number": 1, "still_path": "/preview-still.jpg", "air_date": "2008-01-20" },
            { "id": 62086, "name": "Cat's in the Bag...", "overview": "Cleaning up.", "episode_number": 2, "season_number": 1, "still_path": null, "air_date": "2008-01-27" },
            { "id": 62087, "name": "...And the Bag's in the River", "overview": "A decision.", "episode_number": 3, "season_number": 1, "still_path": "/preview-still.jpg", "air_date": "2008-02-10" }
          ]
        }
        """
    )

    static let person: PersonDetail = decode(
        """
        {
          "id": 287,
          "name": "Brad Pitt",
          "biography": "An American actor and film producer.",
          "profile_path": "/preview-face.jpg",
          "known_for_department": "Acting",
          "birthday": "1963-12-18",
          "place_of_birth": "Shawnee, Oklahoma, USA",
          "credits": [
            { "credit_id": "c1", "id": 550, "media_type": "movie", "title": "Fight Club", "character": "Tyler Durden", "poster_path": "/preview-poster.jpg", "release_date": "1999-10-15" },
            { "credit_id": "c2", "id": 1396, "media_type": "tv", "name": "Breaking Bad", "character": "Himself", "poster_path": "/preview-poster.jpg", "first_air_date": "2008-01-20" }
          ]
        }
        """
    )

    static let watchlist: [WatchItem] = decode(
        """
        [
          { "id": 1, "user_id": "preview", "tmdb_id": 550, "media_type": "movie", "status": "completed", "added_at": "2026-01-04T12:00:00Z", "title": "Fight Club", "poster_path": "/preview-poster.jpg" },
          { "id": 2, "user_id": "preview", "tmdb_id": 1396, "media_type": "tv", "status": "watching", "added_at": "2026-02-11T12:00:00Z", "title": "Breaking Bad", "poster_path": "/preview-poster.jpg", "new_episodes_count": 2 },
          { "id": 3, "user_id": "preview", "tmdb_id": 1429, "media_type": "tv", "status": "plan_to_watch", "added_at": "2026-03-02T12:00:00Z", "title": "Attack on Titan", "poster_path": "/preview-poster.jpg", "is_anime": true }
        ]
        """
    )

    static let continueWatching: [ContinueWatchingItem] = decode(
        """
        [
          {
            "id": 2, "tmdb_id": 1396, "title": "Breaking Bad", "poster_path": "/preview-poster.jpg", "is_anime": false,
            "next_episode": { "season_number": 1, "episode_number": 4, "name": "Cancer Man", "still_path": "/preview-still.jpg", "air_date": "2008-02-17" }
          },
          {
            "id": 3, "tmdb_id": 1429, "title": "Attack on Titan", "poster_path": "/preview-poster.jpg", "is_anime": true,
            "next_episode": { "season_number": 2, "episode_number": 1, "name": "Beast Titan", "still_path": null, "air_date": "2017-04-01" }
          }
        ]
        """
    )

    static let upcoming: [UpcomingItem] = decode(
        """
        [
          {
            "tmdb_id": 1396, "title": "Breaking Bad", "poster_path": "/preview-poster.jpg", "is_anime": false,
            "watch_providers": ["Netflix"],
            "next_episode": { "season_number": 6, "episode_number": 1, "name": "Nova temporada", "air_date": "2030-01-01", "still_path": "/preview-still.jpg", "days_until_air": 30 }
          }
        ]
        """
    )

    static let providers: [StreamingProvider] = decode(
        """
        [
          { "provider_id": 8, "provider_name": "Netflix", "logo_path": "/preview-logo.jpg" },
          { "provider_id": 119, "provider_name": "Prime Video", "logo_path": "/preview-logo.jpg" },
          { "provider_id": 337, "provider_name": "Disney Plus", "logo_path": "/preview-logo.jpg" }
        ]
        """
    )

    static let genres: [Genre] = [
        Genre(id: 28, name: "Ação"),
        Genre(id: 35, name: "Comédia"),
        Genre(id: 18, name: "Drama")
    ]

    static let stats: ProfileStats = ProfileStats(
        episodesWatched: 428,
        moviesWatched: 96,
        showsCompleted: 14,
        titlesRated: 61,
        averageRating: 8
    )

    // MARK: - Decoding

    /// Traps on malformed literals on purpose: these are compile-time constants of this file,
    /// so a failure is a typo in the JSON above and never something a running app can hit.
    private static func decode<T: Decodable>(_ json: String) -> T {
        do {
            return try APIClient.makeDecoder().decode(T.self, from: Data(json.utf8))
        } catch {
            fatalError("PreviewLibrary: malformed fixture for \(T.self) — \(error)")
        }
    }
}
