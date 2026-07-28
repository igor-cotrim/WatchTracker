import Foundation
import Testing
@testable import WatchTracker

@Suite("WatchTrackerExporter", .tags(.pure))
struct WatchTrackerExporterTests {

    private func files(
        _ entries: [ExportEntry],
        episodes: [ExportEpisode] = [],
    ) -> [ExportFile] {
        WatchTrackerExporter.files(
            from: TestFixtures.exportPayload(items: entries, episodes: episodes),
        )
    }

    private func rows(_ files: [ExportFile], named name: String) -> [[String]] {
        guard let file = files.first(where: { $0.name == name }) else { return [] }
        return CSVParser.parse(file.content)
    }

    @Test func `returns no files for an empty library`() {
        #expect(files([]).isEmpty)
    }

    @Test func `writes movies and shows into a single file`() {
        let generated = files([
            TestFixtures.exportEntry(status: .completed, rating: 9, ratedAt: "2026-03-11T00:00:00Z"),
            TestFixtures.exportEntry(
                tmdbId: 95396,
                mediaType: .tv,
                title: "Severance",
                year: 2022,
                status: .watching,
            ),
        ])

        #expect(generated.map(\.name) == ["watchtracker.csv"])
        #expect(rows(generated, named: "watchtracker.csv") == [
            ["Name", "Year", "Media Type", "Status", "Rating", "Watched Date", "TMDB ID"],
            ["Fight Club", "1999", "movie", "completed", "4.5", "2026-03-11", "550"],
            ["Severance", "2022", "tv", "watching", "", "2026-01-02", "95396"],
        ])
    }

    @Test func `writes episodes into their own file with the show name`() {
        let generated = files(
            [TestFixtures.exportEntry(tmdbId: 95396, mediaType: .tv, title: "Severance", year: 2022)],
            episodes: [
                TestFixtures.exportEpisode(seasonNumber: 1, episodeNumber: 1),
                TestFixtures.exportEpisode(seasonNumber: 1, episodeNumber: 2, watchedAt: nil),
            ],
        )

        #expect(generated.map(\.name) == ["watchtracker.csv", "episodes.csv"])
        #expect(rows(generated, named: "episodes.csv") == [
            ["Name", "TMDB ID", "Season", "Episode", "Watched Date"],
            ["Severance", "95396", "1", "1", "2026-02-01"],
            ["Severance", "95396", "1", "2", ""],
        ])
    }

    @Test func `leaves the show name blank when the show is not in the library`() {
        let generated = files([], episodes: [TestFixtures.exportEpisode(tmdbId: 1396)])

        #expect(generated.map(\.name) == ["episodes.csv"])
        #expect(rows(generated, named: "episodes.csv")[1] == ["", "1396", "1", "1", "2026-02-01"])
    }

    @Test func `keeps a status the WatchlistStatus enum has no case for`() {
        let generated = files([TestFixtures.exportEntry(rawStatus: "dropped")])

        #expect(rows(generated, named: "watchtracker.csv")[1][3] == "dropped")
    }

    // MARK: - Round trip

    @Test func `every field survives a round trip through the parser`() {
        let entries = [
            TestFixtures.exportEntry(
                tmdbId: 550,
                title: "Fight Club",
                year: 1999,
                status: .completed,
                rating: 9,
                ratedAt: "2026-03-11T00:00:00Z",
            ),
            TestFixtures.exportEntry(
                tmdbId: 95396,
                mediaType: .tv,
                title: "Severance",
                year: 2022,
                rawStatus: "dropped",
            ),
        ]
        let episodes = [TestFixtures.exportEpisode(seasonNumber: 2, episodeNumber: 4)]

        let imported = files(entries, episodes: episodes)
            .map { ImportedFile(name: $0.name, content: $0.content) }
        let batch = ImportParser.parse(files: imported)

        let fightClub = batch.items.first { $0.title == "Fight Club" }
        #expect(fightClub?.tmdbId == 550)
        #expect(fightClub?.mediaType == .movie)
        #expect(fightClub?.year == 1999)
        #expect(fightClub?.status == WatchlistStatus.completed.rawValue)
        #expect(fightClub?.rating == 9)
        #expect(fightClub?.watchedDate == "2026-03-11")

        let severance = batch.items.first { $0.title == "Severance" }
        #expect(severance?.tmdbId == 95396)
        #expect(severance?.mediaType == .tv)
        #expect(severance?.status == "dropped", "a status the enum cannot express still round-trips")

        #expect(batch.episodes == [
            ImportEpisode(tmdbId: 95396, seasonNumber: 2, episodeNumber: 4, watchedDate: "2026-02-01"),
        ])
        #expect(batch.source == "watchtracker")
    }
}
