import Foundation

/// Which CSV layout the export screen produces.
enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    /// One file (plus `episodes.csv`) carrying TMDB ids, TV shows and every
    /// status. The only format that imports back without losing anything.
    case watchTracker
    /// The four Letterboxd-shaped files. Movies only in the first three, so they
    /// stay valid for Letterboxd's own importer.
    case letterboxd

    var id: String { rawValue }

    var title: String {
        switch self {
        case .watchTracker: return Strings.Export.formatWatchTracker
        case .letterboxd: return Strings.Export.formatLetterboxd
        }
    }

    var summary: String {
        switch self {
        case .watchTracker: return Strings.Export.formatWatchTrackerHint
        case .letterboxd: return Strings.Export.formatLetterboxdHint
        }
    }
}
