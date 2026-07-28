import Foundation

/// Minimal RFC-4180 CSV writer — the counterpart to `CSVParser`. Quotes a field
/// only when it contains a delimiter, a quote, or a line break, and escapes
/// embedded quotes by doubling them. Rows are LF-terminated, including the last.
enum CSVWriter {
    static func serialize(_ rows: [[String]]) -> String {
        guard !rows.isEmpty else { return "" }
        return rows
            .map { row in row.map(escape).joined(separator: ",") }
            .joined(separator: "\n")
            + "\n"
    }

    /// Builds a named file from a header plus one row per element.
    static func file<Element>(
        named name: String,
        header: [String],
        rows elements: [Element],
        row: (Element) -> [String],
    ) -> ExportFile {
        ExportFile(
            name: name,
            content: serialize([header] + elements.map(row)),
            rowCount: elements.count,
        )
    }

    private static func escape(_ field: String) -> String {
        let needsQuoting = field.contains(",")
            || field.contains("\"")
            || field.contains("\n")
            || field.contains("\r")

        guard needsQuoting else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
