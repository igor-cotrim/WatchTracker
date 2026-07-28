import Foundation
@testable import WatchTracker

@MainActor
final class MockAnalytics: AnalyticsTracking {
    private(set) var captured: [(event: AnalyticsEvent, properties: [String: Any])] = []

    var capturedEvents: [AnalyticsEvent] { captured.map(\.event) }

    func capture(_ event: AnalyticsEvent, properties: [String: Any]) {
        captured.append((event: event, properties: properties))
    }

    func properties(for event: AnalyticsEvent) -> [String: Any]? {
        captured.last(where: { $0.event == event })?.properties
    }
}
