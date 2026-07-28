import Foundation
import Testing
@testable import WatchTracker

@Suite("LetterboxdParser", .tags(.pure))
struct LetterboxdParserTests {

    private func parse(_ files: (name: String, content: String)...) -> [ImportItem] {
        LetterboxdParser.parse(files: files.map { ImportedFile(name: $0.name, content: $0.content) })
    }

    private func item(_ items: [ImportItem], title: String) -> ImportItem? {
        items.first { $0.title == title }
    }

    // MARK: File roles

    @Test func `watched csv marks titles as completed`() {
        let items = parse((name: "watched.csv", content: """
        Date,Name,Year,Letterboxd URI
        2026-01-01,Dune,2021,https://boxd.it/a
        """))

        #expect(items.count == 1)
        #expect(items[0].title == "Dune")
        #expect(items[0].year == 2021)
        #expect(items[0].status == WatchlistStatus.completed.rawValue)
    }

    @Test func `watchlist csv marks titles as plan to watch`() {
        let items = parse((name: "watchlist.csv", content: """
        Date,Name,Year,Letterboxd URI
        2026-01-01,Arrival,2016,https://boxd.it/b
        """))

        #expect(items[0].status == WatchlistStatus.planToWatch.rawValue)
    }

    @Test func `ratings csv marks completed and carries a rating`() {
        let items = parse((name: "ratings.csv", content: """
        Date,Name,Year,Letterboxd URI,Rating
        2026-01-01,Dune,2021,https://boxd.it/a,4.5
        """))

        #expect(items[0].status == WatchlistStatus.completed.rawValue)
        #expect(items[0].rating == 9)
    }

    @Test func `an unrecognised file is skipped`() {
        let items = parse((name: "comments.csv", content: "Foo,Bar\n1,2"))
        #expect(items.isEmpty)
    }

    @Test func `a renamed file falls back to column inference`() {
        let items = parse((name: "export-1.csv", content: """
        Date,Name,Year,Rating
        2026-01-01,Dune,2021,3.0
        """))
        #expect(items.first?.rating == 6)
    }

    // MARK: Rating normalisation

    @Test(arguments: [
        (stars: "0.5", expected: 1),
        (stars: "1.0", expected: 2),
        (stars: "2.5", expected: 5),
        (stars: "3.0", expected: 6),
        (stars: "4.5", expected: 9),
        (stars: "5.0", expected: 10),
    ])
    func `Letterboxd stars map onto the ten-point scale`(stars: String, expected: Int) {
        let items = parse((name: "ratings.csv", content: """
        Date,Name,Year,Rating
        2026-01-01,Film,2020,\(stars)
        """))
        #expect(items.first?.rating == expected)
    }

    @Test func `a missing rating leaves the field nil`() {
        let items = parse((name: "ratings.csv", content: """
        Date,Name,Year,Rating
        2026-01-01,Film,2020,
        """))
        #expect(items.first?.rating == nil)
        #expect(items.first?.status == WatchlistStatus.completed.rawValue)
    }

    // MARK: Aggregation across files

    @Test func `the same film across files collapses into one item`() {
        let items = parse(
            (name: "watched.csv", content: "Date,Name,Year\n2026-01-01,Dune,2021"),
            (name: "ratings.csv", content: "Date,Name,Year,Rating\n2026-01-02,Dune,2021,4.0")
        )

        #expect(items.count == 1)
        #expect(items[0].status == WatchlistStatus.completed.rawValue)
        #expect(items[0].rating == 8)
    }

    @Test func `matching is case-insensitive on the title`() {
        let items = parse(
            (name: "watched.csv", content: "Date,Name,Year\n2026-01-01,DUNE,2021"),
            (name: "ratings.csv", content: "Date,Name,Year,Rating\n2026-01-02,dune,2021,4.0")
        )
        #expect(items.count == 1)
    }

    @Test func `the same title in different years stays separate`() {
        let items = parse((name: "watched.csv", content: """
        Date,Name,Year
        2026-01-01,Dune,1984
        2026-01-02,Dune,2021
        """))
        #expect(items.count == 2)
    }

    @Test func `completed wins over plan to watch`() {
        let items = parse(
            (name: "watchlist.csv", content: "Date,Name,Year\n2026-01-01,Dune,2021"),
            (name: "watched.csv", content: "Date,Name,Year\n2026-01-02,Dune,2021")
        )
        #expect(items.count == 1)
        #expect(items[0].status == WatchlistStatus.completed.rawValue)
    }

    // MARK: Watched date

    @Test func `diary prefers its own Watched Date column`() {
        let items = parse((name: "diary.csv", content: """
        Date,Name,Year,Watched Date,Rating
        2026-03-01,Dune,2021,2026-02-14,4.0
        """))
        #expect(items.first?.watchedDate == "2026-02-14")
    }

    @Test func `diary falls back to Date when Watched Date is blank`() {
        let items = parse((name: "diary.csv", content: """
        Date,Name,Year,Watched Date,Rating
        2026-03-01,Dune,2021,,4.0
        """))
        #expect(items.first?.watchedDate == "2026-03-01")
    }

    // MARK: Malformed input

    @Test func `a header-only file yields nothing`() {
        #expect(parse((name: "watched.csv", content: "Date,Name,Year")).isEmpty)
    }

    @Test func `rows without a title are skipped`() {
        let items = parse((name: "watched.csv", content: """
        Date,Name,Year
        2026-01-01,,2021
        2026-01-02,Dune,2021
        """))
        #expect(items.count == 1)
        #expect(items[0].title == "Dune")
    }

    @Test func `a non-numeric year becomes nil`() {
        let items = parse((name: "watched.csv", content: """
        Date,Name,Year
        2026-01-01,Dune,n/a
        """))
        #expect(items.first?.year == nil)
    }

    @Test func `quoted titles containing commas survive`() {
        let items = parse((name: "watched.csv", content: """
        Date,Name,Year
        2026-01-01,"Crouching Tiger, Hidden Dragon",2000
        """))
        #expect(items.first?.title == "Crouching Tiger, Hidden Dragon")
    }

    @Test func `an empty file list yields nothing`() {
        #expect(LetterboxdParser.parse(files: []).isEmpty)
    }
}
