import SwiftUI

@main
struct ScentenceApp: App {
    @StateObject private var authState = AuthState()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}
