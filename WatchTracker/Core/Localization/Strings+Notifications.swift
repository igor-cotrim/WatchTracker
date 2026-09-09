import Foundation

extension Strings {
    // MARK: - Notifications

    enum Notifications {
        static var episodeReminders: String { String(localized: "notifications.episode_reminders") }
        static var newSeasonSubtitle: String { String(localized: "notifications.new_season_subtitle") }
        static func newSeasonBody(season: Int) -> String {
            String(format: String(localized: "notifications.new_season_body"), season)
        }
    }
}
