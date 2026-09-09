import Foundation

/// One `Codable` value that survives a relaunch.
///
/// A protocol because the two things that use it — the watchlist snapshot and the pending
/// write queue — must not touch the disk from a `#Preview` or a test, and because "did this
/// get saved?" is then a fact a test can assert instead of a file it has to go looking for.
protocol FileArchiving<Value>: Sendable {
    associatedtype Value: Codable & Sendable

    func load() -> Value?
    func save(_ value: Value)
    func delete()
}

/// A JSON file in Application Support.
///
/// Application Support rather than Caches because the system may evict Caches under disk
/// pressure, and a queue of the user's unsent changes is not something to lose that way.
///
/// Every operation is best-effort: a cache that fails to save is a slower next launch, never
/// an error worth interrupting anyone over, so failures are swallowed by design.
struct JSONFileArchive<Value: Codable & Sendable>: FileArchiving {
    private let url: URL?

    init(filename: String, fileManager: FileManager = .default) {
        let directory = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        url = directory?.appendingPathComponent(filename)
    }

    func load() -> Value? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value) {
        guard let url, let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func delete() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

/// Keeps the value in memory only. The default everywhere the real file would be wrong:
/// previews, tests, and any `WatchlistStore` built outside the live container.
final class InMemoryArchive<Value: Codable & Sendable>: FileArchiving, @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value?

    init(_ value: Value? = nil) {
        self.value = value
    }

    func load() -> Value? { lock.withLock { value } }
    func save(_ value: Value) { lock.withLock { self.value = value } }
    func delete() { lock.withLock { value = nil } }
}
