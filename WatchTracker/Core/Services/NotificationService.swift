import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    private init() {}

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleNotifications(for items: [UpcomingItem]) async {
        guard UserDefaults.standard.bool(forKey: "episodeRemindersEnabled") else { return }

        await cancelAllEpisodeNotifications()

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let today = Calendar.current.startOfDay(for: Date())

        for item in items {
            let ep = item.nextEpisode
            guard let airDate = NotificationService.airDate(from: ep.airDate) else { continue }
            guard airDate >= today else { continue }

            let components = NotificationService.triggerComponents(for: airDate)

            let content = UNMutableNotificationContent()
            content.title = item.title
            content.subtitle = "S\(ep.seasonNumber) E\(ep.episodeNumber): \(ep.name)"
            content.body = String(localized: "notifications.new_episode_body")
            content.sound = .default
            content.userInfo = ["tmdbId": item.tmdbId, "mediaType": "tv"]
            content.categoryIdentifier = "EPISODE_NOTIFICATION"

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = NotificationService.episodeIdentifier(
                tmdbId: item.tmdbId,
                season: ep.seasonNumber,
                episode: ep.episodeNumber
            )
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Fires an immediate local notification when a completed show was revived
    /// because a brand-new season aired. Deduped per (show, season) so the same
    /// season never notifies twice across watchlist refreshes.
    func notifyNewSeason(tmdbId: Int, title: String, seasonNumber: Int) async {
        guard UserDefaults.standard.bool(forKey: "episodeRemindersEnabled") else { return }

        let dedupeKey = NotificationService.newSeasonDedupeKey(tmdbId: tmdbId, season: seasonNumber)
        guard !UserDefaults.standard.bool(forKey: dedupeKey) else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = await Strings.Notifications.newSeasonSubtitle
        content.body = await Strings.Notifications.newSeasonBody(season: seasonNumber)
        content.sound = .default
        content.userInfo = ["tmdbId": tmdbId, "mediaType": "tv"]
        content.categoryIdentifier = "NEW_SEASON_NOTIFICATION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let id = NotificationService.newSeasonIdentifier(tmdbId: tmdbId, season: seasonNumber)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
            UserDefaults.standard.set(true, forKey: dedupeKey)
        } catch {
            // Leave the dedupe flag unset so a later refresh can retry.
        }
    }

    func cancelAllEpisodeNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.filter { $0.identifier.hasPrefix(NotificationService.episodePrefix) }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Pure helpers
    //
    // Extracted from the actor so the date handling and identifier shapes can be
    // unit-tested without `UNUserNotificationCenter`.

    nonisolated static let episodePrefix = "episode-"

    /// Parses a TMDB `yyyy-MM-dd` air date. Uses the POSIX locale so the format is
    /// not reinterpreted under non-Gregorian calendars.
    nonisolated static func airDate(from string: String, calendar: Calendar = .current) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return formatter.date(from: string)
    }

    /// Episode reminders fire at 20:00 local time on the air date.
    nonisolated static func triggerComponents(for airDate: Date, calendar: Calendar = .current) -> DateComponents {
        var components = calendar.dateComponents([.year, .month, .day], from: airDate)
        components.hour = 20
        components.minute = 0
        components.second = 0
        return components
    }

    nonisolated static func episodeIdentifier(tmdbId: Int, season: Int, episode: Int) -> String {
        "\(episodePrefix)\(tmdbId)-S\(season)E\(episode)"
    }

    nonisolated static func newSeasonIdentifier(tmdbId: Int, season: Int) -> String {
        "newseason-\(tmdbId)-S\(season)"
    }

    nonisolated static func newSeasonDedupeKey(tmdbId: Int, season: Int) -> String {
        "notifiedNewSeason-\(tmdbId)-\(season)"
    }
}

extension NotificationService: NotificationScheduling {}
