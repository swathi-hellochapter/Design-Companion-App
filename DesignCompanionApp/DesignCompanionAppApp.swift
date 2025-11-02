import SwiftUI

@main
struct DesignCompanionAppApp: App {
    init() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ChapterColors.cream)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(ChapterColors.text)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(ChapterColors.text)]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(ChapterColors.accent)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}