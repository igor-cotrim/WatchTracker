import Testing
import Foundation
@testable import WatchTracker

@Suite(.tags(.service))
struct SearchHistoryManagerTests {

    private func makeManager() -> (SearchHistoryManager, String) {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let manager = SearchHistoryManager(userDefaults: defaults)
        return (manager, suiteName)
    }

    @Test func `load returns empty array on fresh store`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        #expect(manager.load().isEmpty)
    }

    @Test func `save then load returns saved query`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        manager.save(query: "batman")
        #expect(manager.load() == ["batman"])
    }

    @Test func `save deduplicates exact match`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        manager.save(query: "batman")
        manager.save(query: "batman")
        #expect(manager.load().count == 1)
    }

    @Test func `save deduplicates case insensitively`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        manager.save(query: "batman")
        manager.save(query: "Batman")
        let history = manager.load()
        #expect(history.count == 1)
        #expect(history.first == "Batman", "Newer version should be at front")
    }

    @Test func `newer saves appear at front`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        manager.save(query: "first")
        manager.save(query: "second")
        #expect(manager.load().first == "second")
    }

    @Test func `save enforces max 20 items`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        for i in 1...21 {
            manager.save(query: "query\(i)")
        }
        #expect(manager.load().count == 20)
    }

    @Test func `remove deletes specific item`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        manager.save(query: "keep")
        manager.save(query: "remove")
        manager.remove(query: "remove")
        let history = manager.load()
        #expect(history.contains("remove") == false)
        #expect(history.contains("keep"))
    }

    @Test func `remove on missing item leaves list unchanged`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        manager.save(query: "batman")
        manager.remove(query: "superman")
        #expect(manager.load() == ["batman"])
    }

    @Test func `clearAll empties the list`() {
        let (manager, suiteName) = makeManager()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        manager.save(query: "batman")
        manager.save(query: "superman")
        manager.clearAll()
        #expect(manager.load().isEmpty)
    }

    @Test func `two managers on same defaults share state`() {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let manager1 = SearchHistoryManager(userDefaults: defaults)
        let manager2 = SearchHistoryManager(userDefaults: defaults)
        manager1.save(query: "batman")
        #expect(manager2.load() == ["batman"])
    }
}
