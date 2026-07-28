import Foundation

extension Strings {
    // MARK: - Import

    enum Import {
        static var title: String { String(localized: "import.title") }
        static var pickFile: String { String(localized: "import.pick_file") }
        static var pickFileHint: String { String(localized: "import.pick_file_hint") }
        static var importing: String { String(localized: "import.importing") }
        static var resultsTitle: String { String(localized: "import.results_title") }
        static var resultMatched: String { String(localized: "import.result_matched") }
        static var resultWatchlist: String { String(localized: "import.result_watchlist") }
        static var resultRatings: String { String(localized: "import.result_ratings") }
        static var resultEpisodes: String { String(localized: "import.result_episodes") }
        static var unmatchedTitle: String { String(localized: "import.unmatched_title") }
        static var errorEmpty: String { String(localized: "import.error_empty") }
    }
}
