import Foundation

@Observable
final class AppRouter {
    static let shared = AppRouter()

    enum AppTab: Hashable {
        case home, watching, discover, ai, profile

        var analyticsName: String {
            switch self {
            case .home: return "home"
            case .watching: return "watching"
            case .discover: return "discover"
            case .ai: return "ai"
            case .profile: return "profile"
            }
        }
    }

    var selectedTab: AppTab = .home {
        didSet {
            guard selectedTab != oldValue else { return }
            AnalyticsService.shared.capture(.screenView, properties: ["tab": selectedTab.analyticsName])
        }
    }
    var pendingShowId: Int?

    /// Internal rather than private so tests can inject an isolated router, the same
    /// way `WatchlistStore` does. Production code always goes through `shared`.
    init() {}
}
