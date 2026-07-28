import Foundation

/// Reads WatchTracker's own export back in. Every row carries a TMDB id, so no
/// title search is needed and TV shows and statuses survive the round trip.
enum WatchTrackerParser {
    static func items(from table: CSVTable) -> [ImportItem] {
        table.rows.compactMap { row in
            guard let title = table.value(row, "name") else { return nil }

            return ImportItem(
                title: title,
                year: table.value(row, "year").flatMap { Int($0) },
                status: table.value(row, "status"),
                rating: table.value(row, "rating")
                    .flatMap(Double.init)
                    .map { CSVValue.rating(stars: $0) },
                watchedDate: table.value(row, "watched date"),
                tmdbId: table.value(row, "tmdb id").flatMap { Int($0) },
                mediaType: table.value(row, "media type").flatMap { MediaType(rawValue: $0) },
            )
        }
    }

    static func episodes(from table: CSVTable) -> [ImportEpisode] {
        table.rows.compactMap { row in
            guard
                let tmdbId = table.value(row, "tmdb id").flatMap({ Int($0) }),
                let season = table.value(row, "season").flatMap({ Int($0) }),
                let episode = table.value(row, "episode").flatMap({ Int($0) })
            else { return nil }

            return ImportEpisode(
                tmdbId: tmdbId,
                seasonNumber: season,
                episodeNumber: episode,
                watchedDate: table.value(row, "watched date"),
            )
        }
    }
}
