import SwiftUI
import FoundationModels

struct AppTabView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AppContainer.self) private var container

    private var isAIAvailable: Bool {
        if #available(iOS 26, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        return false
    }

    var body: some View {
        @Bindable var router = appRouter
        TabView(selection: $router.selectedTab) {
            Tab(Strings.Tab.home, systemImage: "house.fill", value: AppRouter.AppTab.home) {
                HomeView(container: container)
            }
            Tab(Strings.Tab.watching, systemImage: "play.circle.fill", value: AppRouter.AppTab.watching) {
                WatchingView(container: container)
            }
            Tab(Strings.Tab.discover, systemImage: "magnifyingglass", value: AppRouter.AppTab.discover) {
                DiscoverView(container: container)
            }
            if #available(iOS 26, *), isAIAvailable {
                Tab(Strings.Tab.ai, systemImage: "sparkles", value: AppRouter.AppTab.ai) {
                    AISuggestionsView(container: container)
                }
            }
            Tab(Strings.Tab.profile, systemImage: "person.fill", value: AppRouter.AppTab.profile) {
                ProfileView(container: container)
            }
        }
        .task {
            await container.startup.run()
        }
    }
}

#Preview {
    AppTabView()
        .environment(AppContainer.preview)
        .environment(AppContainer.preview.router)
}
