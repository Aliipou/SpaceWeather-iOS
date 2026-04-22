import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var network: NetworkMonitor
    @EnvironmentObject private var deepLink: DeepLinkHandler
    @AppStorage(Constants.UserDefaultsKeys.onboardingComplete) private var onboardingComplete = false
    @State private var selectedTab = 0

    var body: some View {
        if !onboardingComplete {
            OnboardingView()
        } else {
            mainTabView
                .onChange(of: deepLink.pendingLink) { _, link in
                    guard let link else { return }
                    selectedTab = link.tabIndex
                    _ = deepLink.consume()
                }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            APODListView()
                .environmentObject(favorites)
                .environmentObject(network)
                .tabItem { Label("Explore", systemImage: "sparkles") }
                .tag(0)

            MarsRoverView()
                .tabItem { Label("Mars", systemImage: "globe.americas.fill") }
                .tag(1)

            FavoritesView()
                .environmentObject(favorites)
                .badge(favorites.favorites.count > 0 ? favorites.favorites.count : 0)
                .tabItem { Label("Favorites", systemImage: "heart.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .tint(SpaceTheme.accent)
        .preferredColorScheme(.dark)
    }
}
