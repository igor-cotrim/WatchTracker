import SwiftUI
import FoundationModels

struct AppTabView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AppContainer.self) private var container
    @Environment(\.scenePhase) private var scenePhase

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
        .safeAreaInset(edge: .top, spacing: 0) {
            if !container.network.isOnline {
                NoticeBanner(
                    message: container.hasPendingMutations
                        ? Strings.Offline.bannerWithPendingChanges
                        : Strings.Offline.banner
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: container.network.isOnline)
        .task {
            await container.startup.run()
        }
        // The one place the queue is drained. Screens react to the same reconnect by
        // refetching, and they must do it after the pending writes have landed — otherwise
        // the refetch returns the state the user has already changed and the UI snaps back.
        //
        // Keyed on both halves, not just connectivity: a write can fail on a timeout while
        // the monitor still reports a usable path, and then no reconnect is ever coming to
        // trigger the drain. Watching the queue itself is what stops that write from sitting
        // there forever.
        .task(id: SyncTrigger(container)) {
            await container.syncPendingMutations()
        }
        // A relaunch is covered by `task` above; this is the app coming back from the
        // background, where neither value need have changed while we were not running.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await container.syncPendingMutations() }
        }
    }

    /// What makes another drain attempt worth making. `task(id:)` re-runs whenever it
    /// changes, so a reconnect and a newly-queued write are the same signal here.
    private struct SyncTrigger: Equatable {
        let isOnline: Bool
        let hasPending: Bool

        @MainActor
        init(_ container: AppContainer) {
            isOnline = container.network.isOnline
            hasPending = container.hasPendingMutations
        }
    }
}

#Preview {
    AppTabView()
        .environment(AppContainer.preview)
        .environment(AppContainer.preview.router)
}
