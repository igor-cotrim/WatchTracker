import Foundation

struct LetterboxdFile: Sendable {
    let name: String
    let content: String
}

enum LetterboxdParser {
    private enum Role {
        case watched
        case ratings
        case diary
        case watchlist  
    }

    private struct Aggregate {
        let title: String
        let year: Int?
        var completed = false
        var planToWatch = false
        var rating: Int?
        var watchedDate: String?
    }

    static func parse(files: [LetterboxdFile]) -> [ImportItem] {
        var aggregates: [String: Aggregate] = [:]

        for file in files {
            let rows = CSVParser.parse(file.content)
            guard rows.count > 1 else { continue }

            let header = rows[0].map { normalize($0) }
            var columns: [String: Int] = [:]
            for (index, name) in header.enumerated() where columns[name] == nil {
                columns[name] = index
            }

            guard let role = role(for: file.name, columns: columns) else { continue }

            for row in rows.dropFirst() {
                guard let title = value(row, columns, "name"), !title.isEmpty else { continue }
                let year = value(row, columns, "year").flatMap { Int($0) }
                let key = "\(title.lowercased())|\(year.map(String.init) ?? "?")"

                var agg = aggregates[key] ?? Aggregate(title: title, year: year)

                switch role {
                case .watched:
                    agg.completed = true
                    if agg.watchedDate == nil { agg.watchedDate = value(row, columns, "date") }
                case .ratings:
                    agg.completed = true
                    if let stars = value(row, columns, "rating").flatMap(Double.init) {
                        agg.rating = normalizeRating(stars)
                    }
                    if agg.watchedDate == nil { agg.watchedDate = value(row, columns, "date") }
                case .diary:
                    agg.completed = true
                    if let stars = value(row, columns, "rating").flatMap(Double.init) {
                        agg.rating = normalizeRating(stars)
                    }
                    // Diary's "Watched Date" is the most accurate; prefer it.
                    if let watched = value(row, columns, "watched date"), !watched.isEmpty {
                        agg.watchedDate = watched
                    } else if agg.watchedDate == nil {
                        agg.watchedDate = value(row, columns, "date")
                    }
                case .watchlist:
                    agg.planToWatch = true
                    if agg.watchedDate == nil { agg.watchedDate = value(row, columns, "date") }
                }

                aggregates[key] = agg
            }
        }

        return aggregates.values.compactMap { agg in
            let status: WatchlistStatus?
            if agg.completed {
                status = .completed
            } else if agg.planToWatch {
                status = .planToWatch
            } else {
                status = nil
            }
            // Skip entries with nothing to import.
            guard status != nil || agg.rating != nil else { return nil }
            return ImportItem(
                title: agg.title,
                year: agg.year,
                status: status,
                rating: agg.rating,
                watchedDate: agg.watchedDate?.isEmpty == true ? nil : agg.watchedDate,
            )
        }
    }

    // MARK: - Helpers

    private static func role(for name: String, columns: [String: Int]) -> Role? {
        if name.contains("ratings") { return .ratings }
        if name.contains("diary") { return .diary }
        if name.contains("watchlist") { return .watchlist }
        if name.contains("watched") { return .watched }

        // Fallback: infer from columns for renamed files.
        if columns["watched date"] != nil { return .diary }
        if columns["rating"] != nil { return .ratings }
        if columns["name"] != nil { return .watched }
        return nil
    }

    /// Letterboxd stars are 0.5–5.0; the backend stores 1–10 integers.
    private static func normalizeRating(_ stars: Double) -> Int {
        min(10, max(1, Int((stars * 2).rounded())))
    }

    private static func normalize(_ header: String) -> String {
        header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func value(_ row: [String], _ columns: [String: Int], _ key: String) -> String? {
        guard let index = columns[key], index < row.count else { return nil }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
