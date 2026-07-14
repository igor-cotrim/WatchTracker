import SwiftUI
import FoundationModels

struct AppTabView: View {
    @Environment(AppRouter.self) private var appRouter

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
                HomeView()
            }
            Tab(Strings.Tab.watching, systemImage: "play.circle.fill", value: AppRouter.AppTab.watching) {
                WatchingView()
            }
            Tab(Strings.Tab.discover, systemImage: "magnifyingglass", value: AppRouter.AppTab.discover) {
                DiscoverView()
            }
            if #available(iOS 26, *), isAIAvailable {
                Tab(Strings.Tab.ai, systemImage: "sparkles", value: AppRouter.AppTab.ai) {
                    AISuggestionsView()
                }
            }
            Tab(Strings.Tab.profile, systemImage: "person.fill", value: AppRouter.AppTab.profile) {
                ProfileView()
            }
        }
        .task {
            let defaults = UserDefaults.standard
            if !defaults.bool(forKey: "hasRequestedNotificationPermission") {
                let granted = await NotificationService.shared.requestAuthorization()
                defaults.set(true, forKey: "hasRequestedNotificationPermission")
                if granted { defaults.set(true, forKey: "episodeRemindersEnabled") }
            }

            if let items = try? await WatchlistService().fetchUpcoming() {
                await NotificationService.shared.scheduleNotifications(for: items)
            }
        }
    }
}

#Preview {
    AppTabView()
        .environment(AppRouter.shared)
}
