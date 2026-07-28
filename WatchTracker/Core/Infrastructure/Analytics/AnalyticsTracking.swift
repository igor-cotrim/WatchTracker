import Foundation

@MainActor
protocol AnalyticsTracking {
    func capture(_ event: AnalyticsEvent, properties: [String: Any])
}

extension AnalyticsTracking {
    func capture(_ event: AnalyticsEvent) {
        capture(event, properties: [:])
    }
}
