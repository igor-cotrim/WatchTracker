import Foundation

/// WatchTracker's own CSV layout: one row per title, carrying the TMDB id, the
/// media type and the exact status, plus a second file for episode progress.
/// Everything it writes comes back on import — `WatchTrackerParser` reads it.
enum WatchTrackerExporter {
    static let libraryFileName = "watchtracker.csv"
    static let episodesFileName = "episodes.csv"

    static let libraryHeader = ["Name", "Year", "Media Type", "Status", "Rating", "Watched Date", "TMDB ID"]
    static let episodesHeader = ["Name", "TMDB ID", "Season", "Episode", "Watched Date"]

    static func files(from payload: ExportPayload) -> [ExportFile] {
        let library = CSVWriter.file(
            named: libraryFileName,
            header: libraryHeader,
            rows: payload.items,
            row: libraryRow,
        )

        // Episodes only carry ids; look the show name up so the file is readable.
        var showNames: [Int: String] = [:]
        for item in payload.items where showNames[item.tmdbId] == nil {
            showNames[item.tmdbId] = item.title
        }

        let episodes = CSVWriter.file(
            named: episodesFileName,
            header: episodesHeader,
            rows: payload.episodes,
            row: { episode in episodeRow(episode, showName: showNames[episode.tmdbId]) },
        )

        return [library, episodes].filter { $0.rowCount > 0 }
    }

    // MARK: - Rows

    private static func libraryRow(_ entry: ExportEntry) -> [String] {
        var row: [String] = []
        row.append(entry.title)
        row.append(CSVValue.year(entry.year))
        row.append(entry.mediaType.rawValue)
        row.append(entry.status ?? "")
        row.append(CSVValue.stars(rating: entry.rating))
        row.append(CSVValue.watchDate(for: entry))
        row.append(String(entry.tmdbId))
        return row
    }

    private static func episodeRow(_ episode: ExportEpisode, showName: String?) -> [String] {
        var row: [String] = []
        row.append(showName ?? "")
        row.append(String(episode.tmdbId))
        row.append(String(episode.seasonNumber))
        row.append(String(episode.episodeNumber))
        row.append(CSVValue.date(episode.watchedAt))
        return row
    }
}
