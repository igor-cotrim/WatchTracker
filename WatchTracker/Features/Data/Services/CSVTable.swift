import Foundation

/// A parsed CSV file with its header indexed by lowercased column name, so the
/// parsers can read cells by name and probe which columns a file has.
struct CSVTable {
    let columns: [String: Int]
    /// Data rows, header excluded.
    let rows: [[String]]

    /// Returns nil for a file with no data rows — nothing to import.
    init?(_ content: String) {
        let parsed = CSVParser.parse(content)
        guard let header = parsed.first, parsed.count > 1 else { return nil }

        var columns: [String: Int] = [:]
        for (index, name) in header.enumerated() {
            let key = Self.normalize(name)
            if columns[key] == nil { columns[key] = index }
        }

        self.columns = columns
        self.rows = Array(parsed.dropFirst())
    }

    func has(_ column: String) -> Bool {
        columns[column] != nil
    }

    /// The trimmed cell, or nil when the column is missing or the cell is blank.
    func value(_ row: [String], _ column: String) -> String? {
        guard let index = columns[column], index < row.count else { return nil }
        let trimmed = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalize(_ header: String) -> String {
        header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
