import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .search
    @Published var pendingSearchQuery: String?
    @AppStorage("isDarkMode") var isDarkMode: Bool = false

    enum AppTab: Hashable {
        case search, favorites, history, profile
    }

    func repeatSearch(query: String) {
        pendingSearchQuery = query
        selectedTab = .search
    }
}
