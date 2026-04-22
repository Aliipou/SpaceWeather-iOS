import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var network: NetworkMonitor
    @AppStorage(Constants.UserDefaultsKeys.onboardingComplete) private var onboardingComplete = false

    var body: some View {
        if !onboardingComplete {
            OnboardingView()
        } else {
            mainTabView
        }
    }

    private var mainTabView: some View {
        TabView {
            APODListView()
                .environmentObject(favorites)
                .environmentObject(network)
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }

            MarsRoverView()
                .tabItem {
                    Label("Mars", systemImage: "globe.americas.fill")
                }

            FavoritesView()
                .environmentObject(favorites)
                .badge(favorites.favorites.count > 0 ? favorites.favorites.count : 0)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(SpaceTheme.accent)
        .preferredColorScheme(.dark)
    }
}
