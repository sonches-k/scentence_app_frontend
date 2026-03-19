import SwiftUI

struct RootView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if authState.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authState.isAuthenticated)
    }
}
