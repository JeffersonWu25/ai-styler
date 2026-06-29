import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService()

    var body: some View {
        Group {
            if authService.isCheckingSession {
                ProgressView("Loading…")
            } else if authService.isAuthenticated {
                MainTabView(authService: authService)
            } else {
                LoginView(authService: authService)
            }
        }
    }
}

private struct MainTabView: View {
    @Bindable var authService: AuthService
    @State private var tryOnSession: TryOnSession
    @State private var collectionsStore: CollectionsStore
    @State private var userPhotosStore: UserPhotosStore

    init(authService: AuthService) {
        self.authService = authService
        _tryOnSession = State(initialValue: TryOnSession(authService: authService))
        _collectionsStore = State(initialValue: CollectionsStore(authService: authService))
        _userPhotosStore = State(initialValue: UserPhotosStore(authService: authService))
    }

    var body: some View {
        TabView(selection: $tryOnSession.selectedTab) {
            HomeView(
                userPhotosStore: userPhotosStore,
                tryOnSession: tryOnSession,
                authService: authService
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
