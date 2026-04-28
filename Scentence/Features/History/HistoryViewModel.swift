import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var history: [SearchHistoryEntry] = []
    @Published var isLoading = false

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    func load(token: String) async {
        isLoading = true
        defer { isLoading = false }
        history = (try? await api.getHistory(token: token)) ?? []
    }

    func deleteEntry(id: Int, token: String) async {
        _ = try? await api.deleteHistoryEntry(entryId: id, token: token)
        history.removeAll { $0.id == id }
    }

    func clearAll(token: String) async {
        _ = try? await api.clearHistory(token: token)
        history = []
    }
}
