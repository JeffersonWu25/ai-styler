import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService()
    @State private var userPhotos = UserPhotos()

    var body: some View {
        Group {
            if authService.isCheckingSession {
                ProgressView("Loading…")
            } else if authService.isAuthenticated {
                MainTabView(authService: authService, userPhotos: userPhotos)
            } else {
                LoginView(authService: authService)
            }
        }
    }
}

private struct MainTabView: View {
    @Bindable var authService: AuthService
    @Bindable var userPhotos: UserPhotos
    @State private var tryOnSession: TryOnSession

    init(authService: AuthService, userPhotos: UserPhotos) {
        self.authService = authService
        self.userPhotos = userPhotos
        _tryOnSession = State(initialValue: TryOnSession(authService: authService))
    }

    var body: some View {
        TabView(selection: $tryOnSession.selectedTab) {
            HomeView(
                userPhotos: userPhotos,
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
        }
    }
}

#Preview {
    ContentView()
}
