import SwiftUI

@main
struct SpaceExplorerApp: App {
    @StateObject private var favorites = FavoritesStore.shared
    @StateObject private var network = NetworkMonitor.shared

    init() {
        configureURLCache()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favorites)
                .environmentObject(network)
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Setup

    private func configureURLCache() {
        URLCache.shared = URLCache(
            memoryCapacity: Constants.Cache.memoryCapacity,
            diskCapacity: Constants.Cache.diskCapacity
        )
    }

    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = UIColor(SpaceTheme.background).withAlphaComponent(0.85)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(SpaceTheme.background)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
