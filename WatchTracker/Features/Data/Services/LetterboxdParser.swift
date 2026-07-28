import Foundation

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

    static func parse(files: [ImportedFile]) -> [ImportItem] {
        var aggregates: [String: Aggregate] = [:]

        for file in files {
            guard
                let table = CSVTable(file.content),
                let role = role(for: file.name, table: table)
            else { continue }

            for row in table.rows {
                guard let title = table.value(row, "name") else { continue }
                let year = table.value(row, "year").flatMap { Int($0) }
                let key = "\(title.lowercased())|\(year.map(String.init) ?? "?")"

                var agg = aggregates[key] ?? Aggregate(title: title, year: year)

                switch role {
                case .watched:
                    agg.completed = true
                    if agg.watchedDate == nil { agg.watchedDate = table.value(row, "date") }
                case .ratings:
                    agg.completed = true
                    if let stars = table.value(row, "rating").flatMap(Double.init) {
                        agg.rating = CSVValue.rating(stars: stars)
                    }
                    if agg.watchedDate == nil { agg.watchedDate = table.value(row, "date") }
                case .diary:
                    agg.completed = true
                    if let stars = table.value(row, "rating").flatMap(Double.init) {
                        agg.rating = CSVValue.rating(stars: stars)
                    }
                    // Diary's "Watched Date" is the most accurate; prefer it.
                    if let watched = table.value(row, "watched date") {
                        agg.watchedDate = watched
                    } else if agg.watchedDate == nil {
                        agg.watchedDate = table.value(row, "date")
                    }
                case .watchlist:
                    agg.planToWatch = true
                    if agg.watchedDate == nil { agg.watchedDate = table.value(row, "date") }
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
                status: status?.rawValue,
                rating: agg.rating,
                watchedDate: agg.watchedDate,
            )
        }
    }

    // MARK: - Helpers

    private static func role(for name: String, table: CSVTable) -> Role? {
        if name.contains("ratings") { return .ratings }
        if name.contains("diary") { return .diary }
        if name.contains("watchlist") { return .watchlist }
        if name.contains("watched") { return .watched }

        // Fallback: infer from columns for renamed files.
        if table.has("watched date") { return .diary }
        if table.has("rating") { return .ratings }
        if table.has("name") { return .watched }
        return nil
    }
}
