import Foundation
import Testing
@testable import WatchTracker

@Suite("CSVParser", .tags(.pure))
struct CSVParserTests {

    @Test func `parses a simple table`() {
        let rows = CSVParser.parse("Name,Year\nDune,2021\nArrival,2016")
        #expect(rows == [["Name", "Year"], ["Dune", "2021"], ["Arrival", "2016"]])
    }

    @Test func `handles a trailing newline without emitting an empty row`() {
        let rows = CSVParser.parse("Name\nDune\n")
        #expect(rows == [["Name"], ["Dune"]])
    }

    @Test func `flushes a final record that is not newline-terminated`() {
        let rows = CSVParser.parse("Name,Year\nDune,2021")
        #expect(rows.count == 2)
        #expect(rows.last == ["Dune", "2021"])
    }

    @Test func `keeps commas inside quoted fields`() {
        let rows = CSVParser.parse("Name,Year\n\"Crouching Tiger, Hidden Dragon\",2000")
        #expect(rows[1] == ["Crouching Tiger, Hidden Dragon", "2000"])
    }

    @Test func `keeps newlines inside quoted fields`() {
        let rows = CSVParser.parse("Name,Review\n\"Dune\",\"Line one\nLine two\"")
        #expect(rows.count == 2)
        #expect(rows[1][1] == "Line one\nLine two")
    }

    @Test func `unescapes doubled quotes`() {
        let rows = CSVParser.parse("Name\n\"He said \"\"hi\"\"\"")
        #expect(rows[1] == ["He said \"hi\""])
    }

    @Test(arguments: ["\r\n", "\r", "\n"])
    func `accepts every line ending`(separator: String) {
        // "\r\n" is a single Swift Character, so it must be normalised before parsing.
        let rows = CSVParser.parse("Name,Year\(separator)Dune,2021")
        #expect(rows == [["Name", "Year"], ["Dune", "2021"]])
    }

    @Test func `preserves empty fields`() {
        let rows = CSVParser.parse("Name,Year,Rating\nDune,,4.5")
        #expect(rows[1] == ["Dune", "", "4.5"])
    }

    @Test func `returns no rows for empty input`() {
        #expect(CSVParser.parse("").isEmpty)
    }

    @Test func `handles ragged rows`() {
        let rows = CSVParser.parse("A,B,C\n1,2")
        #expect(rows[1] == ["1", "2"])
    }
}
