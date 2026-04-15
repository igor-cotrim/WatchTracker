import Foundation

final class SearchHistoryManager {
    private let key = "search_history"
    private let maxItems = 20
    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func save(query: String) {
        var history = load()
        history.removeAll { $0.lowercased() == query.lowercased() }
        history.insert(query, at: 0)
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
        }
        defaults.set(history, forKey: key)
    }

    func remove(query: String) {
        var history = load()
        history.removeAll { $0 == query }
        defaults.set(history, forKey: key)
    }

    func clearAll() {
        defaults.removeObject(forKey: key)
    }
}
