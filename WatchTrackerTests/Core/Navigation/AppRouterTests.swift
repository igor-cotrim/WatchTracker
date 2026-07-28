import Foundation
import Testing
@testable import WatchTracker

@Suite("AppRouter", .tags(.pure, .service))
struct AppRouterTests {

    @Test(arguments: [
        (tab: AppRouter.AppTab.home, name: "home"),
        (tab: .watching, name: "watching"),
        (tab: .discover, name: "discover"),
        (tab: .ai, name: "ai"),
        (tab: .profile, name: "profile"),
    ])
    func `analyticsName is stable per tab`(tab: AppRouter.AppTab, name: String) {
        #expect(tab.analyticsName == name)
    }
}
