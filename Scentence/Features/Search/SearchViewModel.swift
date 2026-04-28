import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var queryText: String = ""
    @Published var searchResponse: SearchResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showFilters: Bool = false
    @Published var limitText: String = "5"
    /// Провайдер который реально сработал для последнего результата (DS или AI).
    @Published var activeProvider: LLMProvider = .deepseek
    /// Ошибка Apple Intelligence если AI не смог сгенерировать (фолбэк на DS).
    @Published var aiError: String?

    var searchLimit: Int { max(1, min(20, Int(limitText) ?? 5)) }

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

    func search(token: String?, llmProvider: LLMProvider) async {
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
            var response = try await api.search(request: request, token: token)
            aiError = nil
            activeProvider = .deepseek

            // Если выбран Apple Intelligence — перегенерируем пирамиду и объяснение локально.
            // При ошибке показываем причину и используем ответ бэкенда как фолбэк.
            if llmProvider == .appleIntelligence, #available(iOS 26, *) {
                guard AppleIntelligenceService.isAvailable else {
                    aiError = "Apple Intelligence недоступен. Включите его в Настройках (Apple Intelligence & Siri) и установите язык Siri на английский."
                    searchResponse = response
                    return
                }
            }
            if llmProvider == .appleIntelligence, #available(iOS 26, *),
               AppleIntelligenceService.isAvailable {
                do {
                    let (pyramid, explanation) = try await AppleIntelligenceService.shared
                        .generate(query: query, perfumes: response.perfumes)
                    response = response.replacing(notePyramid: pyramid, explanation: explanation)
                    activeProvider = .appleIntelligence
                } catch {
                    aiError = "Apple Intelligence: \(error.localizedDescription). Показан результат DeepSeek."
                }
            }

            searchResponse = response
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
