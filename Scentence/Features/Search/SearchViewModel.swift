import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var queryText: String = ""
    @Published var searchResponse: SearchResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showFilters: Bool = false
    /// Raw text for limit input — pre-filled "5", parsed to Int on search
    @Published var limitText: String = "5"

    var searchLimit: Int { max(1, min(50, Int(limitText) ?? 5)) }

    let filtersVM: FiltersViewModel
    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
        self.filtersVM = FiltersViewModel(api: api)
        // Фильтры не требуют авторизации — грузим сразу при создании VM.
        // URLCache обеспечит 304 при повторных запросах.
        Task { await self.filtersVM.loadFilters(token: nil) }
    }

    var hasResults: Bool { searchResponse != nil }

    func search(token: String?) async {
        let query = queryText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 3 else {
            errorMessage = "Запрос должен содержать не менее 3 символов"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let filters = filtersVM.buildFilters()
        let request = SearchRequest(query: query, filters: filters, limit: searchLimit)

        do {
            searchResponse = try await api.search(request: request, token: token)
        } catch is CancellationError {
            // пользователь отменил запрос — не показываем ошибку
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelSearch() {
        isLoading = false
        errorMessage = nil
    }

    func clear() {
        queryText = ""
        searchResponse = nil
        errorMessage = nil
    }
}
