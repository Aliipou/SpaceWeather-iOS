import SwiftUI
import BackgroundTasks

@main
struct SpaceExplorerApp: App {
    @StateObject private var favorites = FavoritesStore.shared
    @StateObject private var network = NetworkMonitor.shared
    @StateObject private var notifications = NotificationManager.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared

    init() {
        configureURLCache()
        configureAppearance()
        BackgroundTaskManager.shared.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favorites)
                .environmentObject(network)
                .environmentObject(notifications)
                .environmentObject(deepLinkHandler)
                .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .openAPODTab)) { _ in
                    deepLinkHandler.pendingLink = .apodList
                }
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
