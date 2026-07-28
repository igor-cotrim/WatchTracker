import Foundation

extension Strings {
    // MARK: - Notifications

    enum Notifications {
        static var sectionTitle: String { String(localized: "notifications.section_title") }
        static var episodeReminders: String { String(localized: "notifications.episode_reminders") }
        static var newEpisodeBody: String { String(localized: "notifications.new_episode_body") }
        static var newSeasonSubtitle: String { String(localized: "notifications.new_season_subtitle") }
        static func newSeasonBody(season: Int) -> String {
            String(format: String(localized: "notifications.new_season_body"), season)
        }
    }
}
