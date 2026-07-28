import Foundation
import Testing
@testable import WatchTracker

@Suite("Episode", .tags(.pure, .model))
struct EpisodeTests {

    private func decodeEpisode(airDate: String?) throws -> Episode {
        let airDateValue = airDate.map { "\"\($0)\"" } ?? "null"
        let json = """
        {
            "id": 1,
            "name": "Pilot",
            "overview": null,
            "episode_number": 1,
            "season_number": 1,
            "still_path": "/still.jpg",
            "air_date": \(airDateValue)
        }
        """
        return try APIClient.makeDecoder().decode(Episode.self, from: Data(json.utf8))
    }

    @Test func `isWatched is local state and decodes as false`() throws {
        // `isWatched` is excluded from CodingKeys — the API never sends it.
        let episode = try decodeEpisode(airDate: nil)
        #expect(episode.isWatched == false)
    }

    @Test func `isWatched is not emitted when encoding`() throws {
        var episode = try decodeEpisode(airDate: nil)
        episode.isWatched = true
        let data = try JSONEncoder().encode(episode)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["isWatched"] == nil)
    }

    @Test func `stillURL uses the w300 TMDB size`() throws {
        let episode = try decodeEpisode(airDate: nil)
        #expect(episode.stillURL?.absoluteString == "https://image.tmdb.org/t/p/w300/still.jpg")
    }

    @Test func `hasAired is true for a past air date`() throws {
        let episode = try decodeEpisode(airDate: TestFixtures.yesterdayDateString())
        #expect(episode.hasAired)
    }

    @Test func `hasAired is false for a future air date`() throws {
        let episode = try decodeEpisode(airDate: TestFixtures.tomorrowDateString())
        #expect(!episode.hasAired)
    }

    @Test(arguments: [nil, "", "not-a-date"])
    func `hasAired defaults to true when the date is missing or unparseable`(airDate: String?) throws {
        let episode = try decodeEpisode(airDate: airDate)
        #expect(episode.hasAired)
    }
}

@Suite("Season", .tags(.pure, .model))
struct SeasonTests {

    @Test func `decodes nested episodes`() throws {
        let json = """
        {
            "id": 10,
            "name": "Season 1",
            "season_number": 1,
            "episode_count": 2,
            "poster_path": "/season.jpg",
            "air_date": "2020-01-01",
            "episodes": [
                {"id": 1, "name": "A", "overview": null, "episode_number": 1, "season_number": 1, "still_path": null, "air_date": null},
                {"id": 2, "name": "B", "overview": null, "episode_number": 2, "season_number": 1, "still_path": null, "air_date": null}
            ]
        }
        """
        let season = try APIClient.makeDecoder().decode(Season.self, from: Data(json.utf8))
        #expect(season.episodes?.count == 2)
        #expect(season.episodeCount == 2)
        #expect(season.episodes?.allSatisfy { !$0.isWatched } == true)
    }

    @Test func `posterURL uses the w185 TMDB size`() throws {
        let json = """
        {"id": 1, "name": "S1", "season_number": 1, "episode_count": null,
         "poster_path": "/season.jpg", "air_date": null, "episodes": null}
        """
        let season = try APIClient.makeDecoder().decode(Season.self, from: Data(json.utf8))
        #expect(season.posterURL?.absoluteString == "https://image.tmdb.org/t/p/w185/season.jpg")
    }

    @Test func `posterURL is nil without a poster path`() {
        #expect(TestFixtures.season().posterURL == nil)
    }
}
