import Foundation

/// Conversions between CSV column values and the app's domain types, shared by
/// both exporters and both parsers so that an export re-imports exactly.
enum CSVValue {
    /// Fixed locale and UTC so the same library always exports the same bytes.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func date(_ date: Date?) -> String {
        guard let date else { return "" }
        return dateFormatter.string(from: date)
    }

    /// The rating date is the closest thing we have to a watch date — the import
    /// route stores the imported watched date there. Falls back to the date the
    /// title was added to the watchlist.
    static func watchDate(for entry: ExportEntry) -> String {
        date(entry.ratedAt ?? entry.addedAt)
    }

    static func year(_ year: Int?) -> String {
        year.map(String.init) ?? ""
    }

    /// The backend's 1–10 integers become Letterboxd's 0.5–5.0 stars, with a
    /// whole number left unsuffixed the way Letterboxd writes them.
    static func stars(rating: Int?) -> String {
        guard let rating else { return "" }
        let stars = Double(rating) / 2
        return stars.rounded() == stars ? String(Int(stars)) : String(format: "%.1f", stars)
    }

    /// The inverse of `stars(rating:)`, clamped to the range the backend accepts.
    static func rating(stars: Double) -> Int {
        min(10, max(1, Int((stars * 2).rounded())))
    }
}
