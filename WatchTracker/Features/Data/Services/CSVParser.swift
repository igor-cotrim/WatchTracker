import Foundation

/// Minimal RFC-4180 CSV parser. Handles quoted fields containing commas,
/// newlines, and escaped double-quotes (`""`). Accepts LF and CRLF line endings.
enum CSVParser {
    static func parse(_ text: String) -> [[String]] {
        // Normalize line endings first. In Swift, "\r\n" is a single Character
        // (grapheme cluster), so a switch on "\n"/"\r" never matches CRLF — the
        // whole file would collapse into one row. Normalizing avoids that.
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var rows: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false

        let chars = Array(normalized)
        var i = 0
        while i < chars.count {
            let c = chars[i]

            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    record.append(field)
                    field = ""
                case "\n":
                    record.append(field)
                    rows.append(record)
                    record = []
                    field = ""
                default:
                    field.append(c)
                }
            }

            i += 1
        }

        // Flush a final record that isn't newline-terminated.
        if !field.isEmpty || !record.isEmpty {
            record.append(field)
            rows.append(record)
        }

        return rows
    }
}
