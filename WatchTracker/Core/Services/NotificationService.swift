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

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        let today = Calendar.current.startOfDay(for: Date())

        for item in items {
            let ep = item.nextEpisode
            guard let airDate = fmt.date(from: ep.airDate) else { continue }
            guard airDate >= today else { continue }

            var components = Calendar.current.dateComponents([.year, .month, .day], from: airDate)
            components.hour = 20
            components.minute = 0
            components.second = 0

            let content = UNMutableNotificationContent()
            content.title = item.title
            content.subtitle = "S\(ep.seasonNumber) E\(ep.episodeNumber): \(ep.name)"
            content.body = String(localized: "notifications.new_episode_body")
            content.sound = .default
            content.userInfo = ["tmdbId": item.tmdbId, "mediaType": "tv"]
            content.categoryIdentifier = "EPISODE_NOTIFICATION"

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "episode-\(item.tmdbId)-S\(ep.seasonNumber)E\(ep.episodeNumber)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Fires an immediate local notification when a completed show was revived
    /// because a brand-new season aired. Deduped per (show, season) so the same
    /// season never notifies twice across watchlist refreshes.
    func notifyNewSeason(tmdbId: Int, title: String, seasonNumber: Int) async {
        guard UserDefaults.standard.bool(forKey: "episodeRemindersEnabled") else { return }

        let dedupeKey = "notifiedNewSeason-\(tmdbId)-\(seasonNumber)"
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
        let id = "newseason-\(tmdbId)-S\(seasonNumber)"
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
        let ids = pending.filter { $0.identifier.hasPrefix("episode-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
