import SwiftUI

struct AppTabView: View {
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
            Tab(Strings.Tab.profile, systemImage: "person.fill") {
                ProfileView()
            }
        }
    }
}

#Preview {
    AppTabView()
}
