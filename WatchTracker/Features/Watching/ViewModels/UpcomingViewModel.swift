import Foundation

@Observable
@MainActor
final class UpcomingViewModel {
    var items: [UpcomingItem] = []
    var isLoading = false
    var errorMessage: String?

    private let service = WatchlistService()

    func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await service.fetchUpcoming()
        } catch {
            errorMessage = error.localizedDescription
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

    private func sectionKey(for days: Int) -> String {
        switch days {
        case ...0: return "today"
        case 1:    return "tomorrow"
        case 2...6: return dayName(offset: days)
        default:   return "later"
        }
    }

    private func dayName(offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = "EEEE"
        return fmt.string(from: date).lowercased()
    }
}
