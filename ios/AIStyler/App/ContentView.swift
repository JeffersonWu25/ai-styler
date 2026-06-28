import SwiftUI

struct ContentView: View {
    @State private var userPhotos = UserPhotos()
    @State private var tryOnSession = TryOnSession()

    var body: some View {
        TabView(selection: $tryOnSession.selectedTab) {
            HomeView(userPhotos: userPhotos, tryOnSession: tryOnSession)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)

            ExploreView(tryOnSession: tryOnSession)
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }
                .tag(AppTab.explore)
        }
    }
}

#Preview {
    ContentView()
}
