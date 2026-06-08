import SwiftUI
import FoundationModels

struct AppTabView: View {
    @Environment(AppRouter.self) private var appRouter

    private var isAIAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    var body: some View {
        @Bindable var router = appRouter
        TabView(selection: $router.selectedTab) {
            Tab(Strings.Tab.home, systemImage: "house.fill", value: AppRouter.AppTab.home) {
                HomeView()
            }
            Tab(Strings.Tab.watching, systemImage: "play.circle.fill", value: AppRouter.AppTab.watching) {
                WatchingView()
            }
            Tab(Strings.Tab.discover, systemImage: "magnifyingglass", value: AppRouter.AppTab.discover) {
                DiscoverView()
            }
            if isAIAvailable {
                Tab(Strings.Tab.ai, systemImage: "sparkles", value: AppRouter.AppTab.ai) {
                    AISuggestionsView()
                }
            }
            Tab(Strings.Tab.profile, systemImage: "person.fill", value: AppRouter.AppTab.profile) {
                ProfileView()
            }
        }
    }
}

#Preview {
    AppTabView()
        .environment(AppRouter.shared)
}
