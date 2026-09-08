import Foundation

extension Strings {
    // MARK: - Detail

    enum Detail {
        static var watchlistAdd: String { String(localized: "detail.watchlist.add") }
        static var watchlistRemove: String { String(localized: "detail.watchlist.remove") }
        static var watchlistWatched: String { String(localized: "detail.watchlist.watched") }
        static var watchlistAccessibilityAdd: String { String(localized: "detail.watchlist.accessibility.add") }
        static var watchlistAccessibilityHint: String { String(localized: "detail.watchlist.accessibility.hint") }
        static var seasons: String { String(localized: "detail.seasons.title") }
        static var synopsis: String { String(localized: "detail.synopsis.title") }
        static var cast: String { String(localized: "detail.cast.title") }
        static var whereToWatch: String { String(localized: "detail.where_to_watch.title") }
        static var recommendations: String { String(localized: "detail.recommendations.title") }
        static var whereToWatchUnavailable: String { String(localized: "detail.where_to_watch.unavailable") }
        static var openInProviderHint: String { String(localized: "detail.where_to_watch.open_in_provider_hint") }
        static var watchTrailer: String { String(localized: "detail.trailer.watch") }
        static var watchTrailerAccessibility: String { String(localized: "detail.trailer.accessibility") }
        static var watchTrailerHint: String { String(localized: "detail.trailer.hint") }
        static var seasonMarkWatched: String { String(localized: "detail.season.mark_watched") }
        static var seasonUnmarkWatched: String { String(localized: "detail.season.unmark_watched") }
        /// Shown on the watchlist button while the title is on the list but its status
        /// has not been read back from the cache yet.
        static var watchlistOnList: String { String(localized: "detail.watchlist.on_list") }
        static var actionErrorTitle: String { String(localized: "detail.action_error.title") }

        static func watchlistAccessibilityOnList(_ status: String) -> String {
            String(format: String(localized: "detail.watchlist.accessibility.on_list"), status)
        }

        static func seasonEpisodesCount(_ count: Int) -> String {
            String(format: String(localized: "detail.season.episodes_count"), count)
        }

        /// Duration shown in the metadata line: "2h 28min" for a movie,
        /// "~45min/ep" for a series, where the number is one episode's length.
        static func runtime(minutes: Int, perEpisode: Bool) -> String {
            let hours = minutes / 60
            let mins = minutes % 60
            let base: String
            switch (hours, mins) {
            case (0, _):
                base = String(format: String(localized: "detail.runtime.minutes"), mins)
            case (_, 0):
                base = String(format: String(localized: "detail.runtime.hours"), hours)
            default:
                base = String(format: String(localized: "detail.runtime.hours_minutes"), hours, mins)
            }
            return perEpisode
                ? String(format: String(localized: "detail.runtime.per_episode"), base)
                : base
        }
    }

    // MARK: - Rating

    enum Rating {
        static var yourRating: String { String(localized: "rating.your_rating") }
        static var tapToRate: String { String(localized: "rating.tap_to_rate") }
        static var startSeries: String { String(localized: "rating.start_series") }
        static var share: String { String(localized: "rating.share") }
        static var shareAccessibility: String { String(localized: "rating.share.accessibility") }
        static var remove: String { String(localized: "rating.remove") }
        static var removeAccessibility: String { String(localized: "rating.remove.accessibility") }
        static var removeConfirmTitle: String { String(localized: "rating.remove.confirm_title") }

        /// Playful caption keyed to the 1–10 rating, shown next to the stars and on the share card.
        static func mood(forRating rating: Int) -> String {
            switch rating {
            case ...2: return String(localized: "rating.mood.awful")
            case 3...4: return String(localized: "rating.mood.meh")
            case 5...6: return String(localized: "rating.mood.decent")
            case 7...8: return String(localized: "rating.mood.great")
            default: return String(localized: "rating.mood.masterpiece")
            }
        }
    }

    // MARK: - Share

    enum Share {
        static var downloadCTA: String { String(localized: "share.download_cta") }
    }
}
