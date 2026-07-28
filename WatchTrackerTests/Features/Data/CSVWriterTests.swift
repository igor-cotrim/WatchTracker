import Testing
@testable import WatchTracker

@Suite("CSVWriter", .tags(.pure))
struct CSVWriterTests {

    @Test func `writes a simple table with a trailing newline`() {
        let csv = CSVWriter.serialize([["Name", "Year"], ["Dune", "2021"]])
        #expect(csv == "Name,Year\nDune,2021\n")
    }

    @Test func `returns an empty string for no rows`() {
        #expect(CSVWriter.serialize([]).isEmpty)
    }

    @Test(arguments: [
        ("plain", "plain"),
        ("has,comma", "\"has,comma\""),
        ("has\"quote", "\"has\"\"quote\""),
        ("has\nnewline", "\"has\nnewline\""),
        ("", ""),
    ])
    func `quotes only the fields that need it`(field: String, expected: String) {
        #expect(CSVWriter.serialize([[field]]) == expected + "\n")
    }

    @Test func `round-trips through CSVParser`() {
        let rows = [
            ["Date", "Name", "Year", "Letterboxd URI"],
            ["2026-03-11", "Once Upon a Time... in Hollywood", "2019", ""],
            ["2026-03-12", "He said \"hello\", then left", "2020", ""],
            ["", "Line\nbreak", "", ""],
        ]

        #expect(CSVParser.parse(CSVWriter.serialize(rows)) == rows)
    }
}
