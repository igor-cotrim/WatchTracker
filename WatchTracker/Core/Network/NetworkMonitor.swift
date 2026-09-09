import Foundation
import Network

/// Whether the device currently has a usable route to the internet.
///
/// A protocol because `NWPathMonitor` is a system boundary like notifications or the
/// keychain: previews and tests need to *be* offline on demand, and nothing else here can
/// make that happen.
@MainActor
protocol NetworkMonitoring: AnyObject, Observable {
    var isOnline: Bool { get }
}

/// Live connectivity, from `NWPathMonitor`.
///
/// Nothing in the app blocks on this — every request is still attempted and every failure
/// still handled, because a satisfied path is not a promise that the request will land.
/// It exists so the UI can say *why* a screen is stale, and so the pending-write queue knows
/// when it is worth draining.
@Observable
@MainActor
final class NetworkMonitor: NetworkMonitoring {
    /// Starts optimistic: `NWPathMonitor` reports asynchronously, and flashing an offline
    /// banner at every launch before the first callback lands is worse than being briefly wrong.
    private(set) var isOnline = true

    @ObservationIgnored
    private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isSatisfied = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self, self.isOnline != isSatisfied else { return }
                self.isOnline = isSatisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.watchtracker.network-monitor"))
    }

    deinit {
        monitor.cancel()
    }
}

/// Offline double for `#Preview`, `AppContainer.preview` and tests. Defaults to online so a
/// canvas render never comes up wearing an offline banner.
@Observable
@MainActor
final class PreviewNetworkMonitor: NetworkMonitoring {
    var isOnline: Bool

    init(isOnline: Bool = true) {
        self.isOnline = isOnline
    }
}
