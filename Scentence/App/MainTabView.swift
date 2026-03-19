import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            SearchView()
                .tabItem {
                    Label("Поиск", systemImage: "sparkles.rectangle.stack")
                }
                .tag(AppState.AppTab.search)

            FavoritesView()
                .tabItem {
                    Label("Избранное", systemImage: "heart")
                }
                .tag(AppState.AppTab.favorites)

            HistoryView()
                .tabItem {
                    Label("История", systemImage: "clock")
                }
                .tag(AppState.AppTab.history)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.circle")
                }
                .tag(AppState.AppTab.profile)
        }
        .tint(AppColor.gold)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}
