import Foundation
import Testing
@testable import WatchTracker

@Suite("LetterboxdExporter", .tags(.pure))
struct LetterboxdExporterTests {

    private func files(_ entries: [ExportEntry]) -> [ExportFile] {
        LetterboxdExporter.files(from: TestFixtures.exportPayload(items: entries))
    }

    /// Parses a generated file back into rows so assertions read as data, not text.
    private func rows(_ files: [ExportFile], named name: String) -> [[String]] {
        guard let file = files.first(where: { $0.name == name }) else { return [] }
        return CSVParser.parse(file.content)
    }

    // MARK: - File selection

    @Test func `omits files that would only contain a header`() {
        let generated = files([TestFixtures.exportEntry(status: .planToWatch)])

        #expect(generated.map(\.name) == ["watchlist.csv"])
    }

    @Test func `returns no files for an empty library`() {
        #expect(files([]).isEmpty)
    }

    @Test func `splits movies across watched, ratings and watchlist`() {
        let generated = files([
            TestFixtures.exportEntry(tmdbId: 550, title: "Fight Club", status: .completed, rating: 9),
            TestFixtures.exportEntry(tmdbId: 438631, title: "Dune", status: .planToWatch),
        ])

        #expect(generated.map(\.name) == ["watched.csv", "ratings.csv", "watchlist.csv"])
        #expect(generated.map(\.rowCount) == [1, 1, 1])
        #expect(rows(generated, named: "watched.csv")[1][1] == "Fight Club")
        #expect(rows(generated, named: "watchlist.csv")[1][1] == "Dune")
    }

    @Test func `keeps TV shows out of the Letterboxd files`() {
        let generated = files([
            TestFixtures.exportEntry(
                tmdbId: 95396,
                mediaType: .tv,
                title: "Severance",
                year: 2022,
                status: .watching,
                rating: 10,
            ),
        ])

        #expect(generated.map(\.name) == ["shows.csv"])
        #expect(rows(generated, named: "shows.csv") == [
            ["Date", "Name", "Year", "Status", "Rating"],
            ["2026-01-02", "Severance", "2022", "watching", "5"],
        ])
    }

    @Test func `exports a status the WatchlistStatus enum has no case for`() {
        // The backend also stores 'dropped'; it must not be silently lost.
        let generated = files([
            TestFixtures.exportEntry(mediaType: .tv, status: nil),
            TestFixtures.exportEntry(tmdbId: 4607, mediaType: .tv, title: "Lost", rawStatus: "dropped"),
        ])

        #expect(rows(generated, named: "shows.csv").count == 3)
        #expect(rows(generated, named: "shows.csv")[2][3] == "dropped")
    }

    // MARK: - Columns

    @Test func `writes the Letterboxd headers`() {
        let generated = files([TestFixtures.exportEntry(status: .completed, rating: 8)])

        #expect(rows(generated, named: "watched.csv")[0] == ["Date", "Name", "Year", "Letterboxd URI"])
        #expect(rows(generated, named: "ratings.csv")[0] == ["Date", "Name", "Year", "Letterboxd URI", "Rating"])
    }

    @Test(arguments: [
        (1, "0.5"), (2, "1"), (5, "2.5"), (9, "4.5"), (10, "5"),
    ])
    func `converts the 1-10 rating back to Letterboxd stars`(rating: Int, stars: String) {
        let generated = files([TestFixtures.exportEntry(status: .completed, rating: rating)])

        #expect(rows(generated, named: "ratings.csv")[1][4] == stars)
    }

    @Test func `prefers the rating date over the date added`() {
        let generated = files([
            TestFixtures.exportEntry(
                status: .completed,
                rating: 8,
                addedAt: "2026-01-02T10:00:00Z",
                ratedAt: "2026-03-11T00:00:00Z",
            ),
        ])

        #expect(rows(generated, named: "watched.csv")[1][0] == "2026-03-11")
    }

    @Test func `falls back to the date added when there is no rating date`() {
        let generated = files([
            TestFixtures.exportEntry(status: .completed, addedAt: "2026-01-02T10:00:00Z"),
        ])

        #expect(rows(generated, named: "watched.csv")[1][0] == "2026-01-02")
    }

    @Test func `leaves the date and year empty when they are unknown`() {
        let generated = files([
            TestFixtures.exportEntry(year: nil, status: .completed, addedAt: nil),
        ])

        #expect(rows(generated, named: "watched.csv")[1] == ["", "Fight Club", "", ""])
    }

    @Test func `escapes titles containing a comma`() {
        let generated = files([
            TestFixtures.exportEntry(title: "Denial, Anger, Acceptance", status: .completed),
        ])

        let file = generated.first { $0.name == "watched.csv" }!
        #expect(file.content.contains("\"Denial, Anger, Acceptance\""))
        #expect(rows(generated, named: "watched.csv")[1][1] == "Denial, Anger, Acceptance")
    }

    // MARK: - Round trip

    @Test func `exported files re-import as the same items`() {
        let entries = [
            TestFixtures.exportEntry(
                tmdbId: 550,
                title: "Fight Club",
                year: 1999,
                status: .completed,
                rating: 9,
                ratedAt: "2026-03-11T00:00:00Z",
            ),
            TestFixtures.exportEntry(tmdbId: 438631, title: "Dune", year: 2021, status: .planToWatch),
        ]

        let imported = files(entries).map { ImportedFile(name: $0.name, content: $0.content) }
        let items = ImportParser.parse(files: imported).items

        let fightClub = items.first { $0.title == "Fight Club" }
        #expect(fightClub?.year == 1999)
        #expect(fightClub?.status == WatchlistStatus.completed.rawValue)
        #expect(fightClub?.rating == 9)
        #expect(fightClub?.watchedDate == "2026-03-11")
        #expect(fightClub?.tmdbId == nil, "the Letterboxd format carries no ids")

        let dune = items.first { $0.title == "Dune" }
        #expect(dune?.year == 2021)
        #expect(dune?.status == WatchlistStatus.planToWatch.rawValue)
        #expect(dune?.rating == nil)
    }
}
