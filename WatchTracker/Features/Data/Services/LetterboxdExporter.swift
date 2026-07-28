import Foundation

/// Turns an `ExportPayload` into Letterboxd-shaped CSV files, the mirror image of
/// `LetterboxdParser`. The three Letterboxd files stay movie-only so they import
/// back into WatchTracker (and into Letterboxd itself) unchanged; TV goes into a
/// separate `shows.csv` that only WatchTracker understands.
///
/// This format carries no TMDB ids, so re-importing it goes through a title
/// search. `WatchTrackerExporter` is the lossless one.
enum LetterboxdExporter {
    static let watchedFileName = "watched.csv"
    static let ratingsFileName = "ratings.csv"
    static let watchlistFileName = "watchlist.csv"
    static let showsFileName = "shows.csv"

    static func files(from payload: ExportPayload) -> [ExportFile] {
        let movies = payload.items.filter { $0.mediaType == .movie }
        let shows = payload.items.filter { $0.mediaType == .tv }

        let watched = CSVWriter.file(
            named: watchedFileName,
            header: ["Date", "Name", "Year", "Letterboxd URI"],
            rows: movies.filter { $0.status == WatchlistStatus.completed.rawValue },
            row: { entry in
                [CSVValue.watchDate(for: entry), entry.title, CSVValue.year(entry.year), ""]
            },
        )

        let ratings = CSVWriter.file(
            named: ratingsFileName,
            header: ["Date", "Name", "Year", "Letterboxd URI", "Rating"],
            rows: movies.filter { $0.rating != nil },
            row: { entry in
                [
                    CSVValue.watchDate(for: entry),
                    entry.title,
                    CSVValue.year(entry.year),
                    "",
                    CSVValue.stars(rating: entry.rating),
                ]
            },
        )

        let watchlist = CSVWriter.file(
            named: watchlistFileName,
            header: ["Date", "Name", "Year", "Letterboxd URI"],
            rows: movies.filter { $0.status == WatchlistStatus.planToWatch.rawValue },
            row: { entry in
                [CSVValue.watchDate(for: entry), entry.title, CSVValue.year(entry.year), ""]
            },
        )

        let showsFile = CSVWriter.file(
            named: showsFileName,
            header: ["Date", "Name", "Year", "Status", "Rating"],
            rows: shows,
            row: { entry in
                [
                    CSVValue.watchDate(for: entry),
                    entry.title,
                    CSVValue.year(entry.year),
                    entry.status ?? "",
                    CSVValue.stars(rating: entry.rating),
                ]
            },
        )

        // A header-only file is noise in the share sheet — drop it.
        return [watched, ratings, watchlist, showsFile].filter { $0.rowCount > 0 }
    }
}
