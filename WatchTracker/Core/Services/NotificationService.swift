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
            components.hour = 9
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

    func cancelAllEpisodeNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.filter { $0.identifier.hasPrefix("episode-") }.map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
