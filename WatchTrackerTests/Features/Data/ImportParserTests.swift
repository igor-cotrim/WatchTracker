import Foundation
import Testing
@testable import WatchTracker

@Suite("ImportParser", .tags(.pure))
struct ImportParserTests {

    private let watchTrackerCSV = """
    Name,Year,Media Type,Status,Rating,Watched Date,TMDB ID
    Fight Club,1999,movie,completed,4.5,2026-03-11,550
    Severance,2022,tv,watching,,2026-02-04,95396
    """

    private let episodesCSV = """
    Name,TMDB ID,Season,Episode,Watched Date
    Severance,95396,1,1,2026-02-01
    Severance,95396,1,2,
    """

    private let letterboxdCSV = """
    Date,Name,Year,Letterboxd URI,Rating
    2026-03-11,Dune,2021,,4
    """

    // MARK: - Detection

    @Test func `reads a WatchTracker library file`() {
        let batch = ImportParser.parse(files: [
            ImportedFile(name: "watchtracker.csv", content: watchTrackerCSV),
        ])

        #expect(batch.items.count == 2)
        #expect(batch.episodes.isEmpty)
        #expect(batch.items[0].tmdbId == 550)
        #expect(batch.items[1].mediaType == .tv)
    }

    @Test func `reads an episodes file`() {
        let batch = ImportParser.parse(files: [
            ImportedFile(name: "episodes.csv", content: episodesCSV),
        ])

        #expect(batch.items.isEmpty)
        #expect(batch.episodes == [
            ImportEpisode(tmdbId: 95396, seasonNumber: 1, episodeNumber: 1, watchedDate: "2026-02-01"),
            ImportEpisode(tmdbId: 95396, seasonNumber: 1, episodeNumber: 2, watchedDate: nil),
        ])
    }

    @Test func `falls back to the Letterboxd parser for files without a TMDB ID column`() {
        let batch = ImportParser.parse(files: [
            ImportedFile(name: "ratings.csv", content: letterboxdCSV),
        ])

        #expect(batch.items.count == 1)
        #expect(batch.items[0].title == "Dune")
        #expect(batch.items[0].tmdbId == nil)
        #expect(batch.items[0].rating == 8, "4 stars is 8 on the backend's scale")
    }

    @Test func `detects the format from the columns, not the file name`() {
        // A renamed export must still be read as the WatchTracker format.
        let batch = ImportParser.parse(files: [
            ImportedFile(name: "my-backup.csv", content: watchTrackerCSV),
        ])

        #expect(batch.items.allSatisfy { $0.tmdbId != nil })
    }

    // MARK: - Mixed selections

    @Test func `accepts a mix of both formats in one selection`() {
        let batch = ImportParser.parse(files: [
            ImportedFile(name: "watchtracker.csv", content: watchTrackerCSV),
            ImportedFile(name: "episodes.csv", content: episodesCSV),
            ImportedFile(name: "ratings.csv", content: letterboxdCSV),
        ])

        #expect(batch.items.map(\.title).sorted() == ["Dune", "Fight Club", "Severance"])
        #expect(batch.episodes.count == 2)
    }

    @Test func `a WatchTracker row wins over a Letterboxd row for the same title`() {
        let duplicate = """
        Date,Name,Year,Letterboxd URI,Rating
        2020-01-01,Fight Club,1999,,2
        """

        let batch = ImportParser.parse(files: [
            ImportedFile(name: "watchtracker.csv", content: watchTrackerCSV),
            ImportedFile(name: "ratings.csv", content: duplicate),
        ])

        let fightClub = batch.items.filter { $0.title == "Fight Club" }
        #expect(fightClub.count == 1, "the duplicate is dropped, not imported twice")
        #expect(fightClub.first?.tmdbId == 550, "the row carrying the id survives")
        #expect(fightClub.first?.rating == 9, "not the 2 stars from the Letterboxd row")
    }

    // MARK: - Malformed input

    @Test(arguments: ["", "Name,Year,TMDB ID", "\n"])
    func `ignores a file with no data rows`(content: String) {
        #expect(ImportParser.parse(files: [ImportedFile(name: "x.csv", content: content)]).isEmpty)
    }

    @Test func `skips rows missing a title or an id`() {
        let content = """
        Name,Year,Media Type,Status,Rating,Watched Date,TMDB ID
        ,1999,movie,completed,,,550
        Fight Club,1999,movie,completed,,,550
        """

        let batch = ImportParser.parse(files: [ImportedFile(name: "w.csv", content: content)])
        #expect(batch.items.map(\.title) == ["Fight Club"])
    }

    @Test func `skips episode rows with a missing number`() {
        let content = """
        Name,TMDB ID,Season,Episode,Watched Date
        Severance,95396,1,,2026-02-01
        Severance,95396,1,2,2026-02-01
        """

        let batch = ImportParser.parse(files: [ImportedFile(name: "e.csv", content: content)])
        #expect(batch.episodes.map(\.episodeNumber) == [2])
    }

    // MARK: - Source

    @Test func `reports the source the batch came from`() {
        let watchTracker = ImportParser.parse(files: [
            ImportedFile(name: "watchtracker.csv", content: watchTrackerCSV),
        ])
        let letterboxd = ImportParser.parse(files: [
            ImportedFile(name: "ratings.csv", content: letterboxdCSV),
        ])
        let episodesOnly = ImportParser.parse(files: [
            ImportedFile(name: "episodes.csv", content: episodesCSV),
        ])

        #expect(watchTracker.source == "watchtracker")
        #expect(letterboxd.source == "letterboxd")
        #expect(episodesOnly.source == "watchtracker")
    }
}
