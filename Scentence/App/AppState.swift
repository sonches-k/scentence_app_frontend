import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .search
    @Published var pendingSearchQuery: String?
    @Published var pendingFilters: SearchFilters?
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("llmProvider") private var llmProviderRaw: String = LLMProvider.deepseek.rawValue

    enum AppTab: Hashable {
        case search, favorites, history, profile
    }

    var llmProvider: LLMProvider {
        get { LLMProvider(rawValue: llmProviderRaw) ?? .deepseek }
        set { llmProviderRaw = newValue.rawValue }
    }

    var isAppleIntelligenceAvailable: Bool {
        if #available(iOS 26, *) {
            return AppleIntelligenceService.isAvailable
        }
        return false
    }

    func repeatSearch(query: String, filters: SearchFilters? = nil) {
        pendingFilters = filters
        pendingSearchQuery = query
        selectedTab = .search
    }
}
