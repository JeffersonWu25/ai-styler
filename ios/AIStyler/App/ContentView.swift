import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

private struct MainTabView: View {
    @State private var apiClient: TryOnAPIClient
    @State private var tryOnSession: TryOnSession
    @State private var collectionsStore: CollectionsStore
    @State private var userPhotosStore: UserPhotosStore

    init() {
        let apiClient = TryOnAPIClient()
        _apiClient = State(initialValue: apiClient)
        _tryOnSession = State(initialValue: TryOnSession(apiClient: apiClient))
        _collectionsStore = State(initialValue: CollectionsStore(apiClient: apiClient))
        _userPhotosStore = State(initialValue: UserPhotosStore(apiClient: apiClient))
    }

    var body: some View {
        TabView(selection: $tryOnSession.selectedTab) {
            HomeView(
                userPhotosStore: userPhotosStore,
                tryOnSession: tryOnSession,
                apiClient: apiClient
            )
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(AppTab.home)

            ExploreView(tryOnSession: tryOnSession)
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }
                .tag(AppTab.explore)

            CollectionsView(
                store: collectionsStore,
                tryOnSession: tryOnSession
            )
            .tabItem {
                Label("Collections", systemImage: "bookmark.fill")
            }
            .tag(AppTab.collections)
        }
        .task {
            async let photos: Void = userPhotosStore.load()
            async let collections: Void = collectionsStore.load()
            async let explore: Void = tryOnSession.restoreLatestGenerationIfNeeded()
            _ = await (photos, collections, explore)
        }
    }
}

#Preview {
    ContentView()
}
