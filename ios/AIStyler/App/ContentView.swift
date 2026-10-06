import SwiftUI

enum AppTab: Hashable {
    case home
    case explore
    case collections
}

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

private struct MainTabView: View {
    @State private var apiClient: APIClient
    @State private var userPhotosStore: UserPhotosStore
    @State private var outfitStore: OutfitStore
    @State private var collectionsStore: CollectionsStore
    @State private var selectedTab: AppTab = .home

    init() {
        let apiClient = APIClient()
        let imageCache = ImageCache(apiClient: apiClient)
        _apiClient = State(initialValue: apiClient)
        _userPhotosStore = State(initialValue: UserPhotosStore(apiClient: apiClient, imageCache: imageCache))
        _outfitStore = State(initialValue: OutfitStore(apiClient: apiClient, imageCache: imageCache))
        _collectionsStore = State(initialValue: CollectionsStore(apiClient: apiClient, imageCache: imageCache))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(userPhotosStore: userPhotosStore, apiClient: apiClient)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)

            ExploreView(
                outfitStore: outfitStore,
                userPhotos: userPhotosStore.userPhotos,
                collectionsStore: collectionsStore
            )
            .tabItem {
                Label("Explore", systemImage: "sparkles")
            }
            .tag(AppTab.explore)

            CollectionsView(store: collectionsStore, selectedTab: $selectedTab)
                .tabItem {
                    Label("Collections", systemImage: "bookmark.fill")
                }
                .tag(AppTab.collections)
        }
        .task {
            async let photos: Void = userPhotosStore.load()
            async let outfits: Void = outfitStore.load()
            async let collections: Void = collectionsStore.load()
            _ = await (photos, outfits, collections)
        }
    }
}

#Preview {
    ContentView()
}
