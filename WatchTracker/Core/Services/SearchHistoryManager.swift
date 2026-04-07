import Foundation

final class SearchHistoryManager {
    private let key = "search_history"
    private let maxItems = 20

    func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func save(query: String) {
        var history = load()
        history.removeAll { $0.lowercased() == query.lowercased() }
        history.insert(query, at: 0)
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
        }
        UserDefaults.standard.set(history, forKey: key)
    }

    func remove(query: String) {
        var history = load()
        history.removeAll { $0 == query }
        UserDefaults.standard.set(history, forKey: key)
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
