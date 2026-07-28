import Foundation

extension Strings {
    // MARK: - Export

    enum Export {
        static var action: String { String(localized: "export.action") }
        static var exporting: String { String(localized: "export.exporting") }
        static var resultsTitle: String { String(localized: "export.results_title") }
        static var share: String { String(localized: "export.share") }
        static var errorEmpty: String { String(localized: "export.error_empty") }
        static var format: String { String(localized: "export.format") }
        static var formatWatchTracker: String { String(localized: "export.format_watchtracker") }
        static var formatWatchTrackerHint: String { String(localized: "export.format_watchtracker_hint") }
        static var formatLetterboxd: String { String(localized: "export.format_letterboxd") }
        static var formatLetterboxdHint: String { String(localized: "export.format_letterboxd_hint") }

        static func fileRows(_ count: Int) -> String {
            String(format: String(localized: "export.file_rows"), count)
        }

        static func unresolved(_ count: Int) -> String {
            String(format: String(localized: "export.unresolved"), count)
        }
    }
}
