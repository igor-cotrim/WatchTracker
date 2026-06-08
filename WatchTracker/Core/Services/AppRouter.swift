import Foundation

@Observable
final class AppRouter {
    static let shared = AppRouter()

    enum AppTab: Hashable {
        case home, watching, discover, ai, profile
    }

    var selectedTab: AppTab = .home
    var pendingShowId: Int?

    private init() {}
}
