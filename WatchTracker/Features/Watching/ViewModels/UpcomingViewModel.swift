import Foundation

@Observable
@MainActor
final class UpcomingViewModel {
    private(set) var items: [UpcomingItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: WatchlistServiceProtocol
    private let notifications: NotificationScheduling
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(service: WatchlistServiceProtocol,
         notifications: NotificationScheduling,
         calendar: Calendar = .current,
         now: @escaping @Sendable () -> Date = Date.init) {
        self.service = service
        self.notifications = notifications
        self.calendar = calendar
        self.now = now
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await service.fetchUpcoming()
            await notifications.scheduleNotifications(for: items)
        } catch {
            errorMessage = error.userFacingMessage
        }
        isLoading = false
    }

    /// Items agrupados por seção de data.
    /// localDaysUntilAir == 0 → "today", 1 → "tomorrow",
    /// 2–6 → nome do dia da semana (chave localizada), ≥7 → "later"
    var groupedItems: [(sectionKey: String, items: [UpcomingItem])] {
        let grouped = Dictionary(grouping: items) { sectionKey(for: $0.nextEpisode.localDaysUntilAir) }
        let nearDayKeys = (2...6).map { dayName(offset: $0) }
        let sortOrder = ["today", "tomorrow"] + nearDayKeys + ["later"]
        return sortOrder.compactMap { key -> (String, [UpcomingItem])? in
            guard let group = grouped[key] else { return nil }
            return (key, group)
        }
    }

    func sectionKey(for days: Int) -> String {
        switch days {
        case ...0: return "today"
        case 1:    return "tomorrow"
        case 2...6: return dayName(offset: days)
        default:   return "later"
        }
    }

    func dayName(offset: Int) -> String {
        let today = now()
        let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
        let formatter = DateFormatter()
        formatter.locale = calendar.locale ?? .current
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).lowercased()
    }
}
