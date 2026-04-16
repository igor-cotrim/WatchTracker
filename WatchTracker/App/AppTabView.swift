import SwiftUI
import FoundationModels

struct AppTabView: View {
    private var isAIAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    var body: some View {
        TabView {
            Tab(Strings.Tab.home, systemImage: "house.fill") {
                HomeView()
            }
            Tab(Strings.Tab.watching, systemImage: "play.circle.fill") {
                WatchingView()
            }
            Tab(Strings.Tab.discover, systemImage: "magnifyingglass") {
                DiscoverView()
            }
            if isAIAvailable {
                Tab(Strings.Tab.ai, systemImage: "sparkles") {
                    AISuggestionsView()
                }
            }
            Tab(Strings.Tab.profile, systemImage: "person.fill") {
                ProfileView()
            }
        }
    }
}

#Preview {
    AppTabView()
}
