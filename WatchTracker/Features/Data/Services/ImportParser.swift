import Foundation

/// Routes each picked file to the parser that understands it, so the user can
/// select a WatchTracker export, a Letterboxd export, or a mix of both without
/// telling us which is which.
enum ImportParser {
    private enum Format {
        case watchTrackerLibrary
        case watchTrackerEpisodes
        case letterboxd
    }

    static func parse(files: [ImportedFile]) -> ImportBatch {
        var batch = ImportBatch()
        var letterboxdFiles: [ImportedFile] = []

        for file in files {
            guard let table = CSVTable(file.content) else { continue }

            switch format(of: table) {
            case .watchTrackerLibrary:
                batch.items.append(contentsOf: WatchTrackerParser.items(from: table))
            case .watchTrackerEpisodes:
                batch.episodes.append(contentsOf: WatchTrackerParser.episodes(from: table))
            case .letterboxd:
                letterboxdFiles.append(file)
            }
        }

        // A WatchTracker row carries a TMDB id, so it always beats a Letterboxd
        // row for the same title — the id imports exactly, the title guesses.
        var seen = Set(batch.items.map(key))
        for item in LetterboxdParser.parse(files: letterboxdFiles) where seen.insert(key(item)).inserted {
            batch.items.append(item)
        }

        return batch
    }

    /// Only our own export writes a TMDB ID column; the Letterboxd files never do.
    private static func format(of table: CSVTable) -> Format {
        guard table.has("tmdb id") else { return .letterboxd }
        return table.has("season") && table.has("episode") ? .watchTrackerEpisodes : .watchTrackerLibrary
    }

    private static func key(_ item: ImportItem) -> String {
        "\(item.title.lowercased())|\(item.year.map(String.init) ?? "?")"
    }
}
