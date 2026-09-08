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

/// Drops every event. Used by `AppContainer.preview` so a canvas render never reaches PostHog.
struct PreviewAnalytics: AnalyticsTracking {
    func capture(_ event: AnalyticsEvent, properties: [String: Any]) {}
}
