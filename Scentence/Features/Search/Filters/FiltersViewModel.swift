import Foundation

@MainActor
final class FiltersViewModel: ObservableObject {

    // MARK: - Static filter options (loaded once)

    @Published var availableGenders: [String] = []
    @Published var availableFamilies: [String] = []
    @Published var availableProductTypes: [String] = []

    // MARK: - Suggest state (brands)

    @Published var brandSuggestions: [String] = []
    @Published var isBrandLoading: Bool = false
    @Published var brandSearchQuery: String = "" {
        didSet { if oldValue != brandSearchQuery { scheduleBrandSearch() } }
    }

    // MARK: - Suggest state (notes)

    @Published var noteSuggestions: [String] = []
    @Published var isNoteLoading: Bool = false
    @Published var noteSearchQuery: String = "" {
        didSet { if oldValue != noteSearchQuery { scheduleNoteSearch() } }
    }

    // MARK: - Selected values

    @Published var selectedGenders: Set<String> = []
    @Published var selectedFamilies: Set<String> = []
    @Published var selectedProductTypes: Set<String> = []
    @Published var selectedBrands: Set<String> = []
    @Published var selectedNotes: Set<String> = []
    @Published var yearFrom: String = ""
    @Published var yearTo: String = ""

    @Published var isLoading: Bool = false

    // MARK: - Private

    private let api: APIServiceProtocol
    private var brandSearchTask: Task<Void, Never>?
    private var noteSearchTask: Task<Void, Never>?
    private var token: String?

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    // MARK: - Computed

    var activeCount: Int {
        var c = 0
        if !selectedGenders.isEmpty      { c += 1 }
        if !selectedFamilies.isEmpty     { c += 1 }
        if !selectedProductTypes.isEmpty { c += 1 }
        if !selectedBrands.isEmpty       { c += 1 }
        if !selectedNotes.isEmpty        { c += 1 }
        if !yearFrom.isEmpty || !yearTo.isEmpty { c += 1 }
        return c
    }

    // MARK: - Load

    func loadFilters(token: String?) async {
        self.token = token
        isLoading = true
        defer { isLoading = false }
        do {
            async let filtersResult   = api.getAllFilters(token: token)
            async let brandsResult    = api.suggestBrands(q: "", token: token)
            async let notesResult     = api.suggestNotes(q: "", token: token)

            let (filters, brands, notes) = try await (filtersResult, brandsResult, notesResult)

            availableGenders      = filters.genders
            availableFamilies     = filters.families
            availableProductTypes = filters.productTypes
            brandSuggestions      = brands
            noteSuggestions       = notes
        } catch {
            // Fail silently — фильтры просто не покажут варианты
        }
    }

    // MARK: - Debounced suggest

    private func scheduleBrandSearch() {
        brandSearchTask?.cancel()
        brandSearchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await fetchBrandSuggestions(q: brandSearchQuery)
        }
    }

    private func scheduleNoteSearch() {
        noteSearchTask?.cancel()
        noteSearchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await fetchNoteSuggestions(q: noteSearchQuery)
        }
    }

    private func fetchBrandSuggestions(q: String) async {
        isBrandLoading = true
        defer { isBrandLoading = false }
        do {
            brandSuggestions = try await api.suggestBrands(q: q, token: token)
        } catch {
            // Оставляем предыдущие результаты при ошибке сети
        }
    }

    private func fetchNoteSuggestions(q: String) async {
        isNoteLoading = true
        defer { isNoteLoading = false }
        do {
            noteSuggestions = try await api.suggestNotes(q: q, token: token)
        } catch {
            // Оставляем предыдущие результаты при ошибке сети
        }
    }

    // MARK: - Reset / Apply / Build

    func reset() {
        selectedGenders      = []
        selectedFamilies     = []
        selectedProductTypes = []
        selectedBrands       = []
        selectedNotes        = []
        yearFrom             = ""
        yearTo               = ""
        brandSearchQuery     = ""
        noteSearchQuery      = ""
    }

    func buildFilters() -> SearchFilters? {
        let filters = SearchFilters(
            genders:      selectedGenders.isEmpty      ? nil : Array(selectedGenders),
            families:     selectedFamilies.isEmpty     ? nil : Array(selectedFamilies),
            productTypes: selectedProductTypes.isEmpty ? nil : Array(selectedProductTypes),
            brands:       selectedBrands.isEmpty       ? nil : Array(selectedBrands),
            notes:        selectedNotes.isEmpty        ? nil : Array(selectedNotes),
            yearFrom:     Int(yearFrom),
            yearTo:       Int(yearTo)
        )
        return filters.isEmpty ? nil : filters
    }

    func apply(from existing: SearchFilters?) {
        guard let f = existing else { reset(); return }
        selectedGenders      = Set(f.genders ?? [])
        selectedFamilies     = Set(f.families ?? [])
        selectedProductTypes = Set(f.productTypes ?? [])
        selectedBrands       = Set(f.brands ?? [])
        selectedNotes        = Set(f.notes ?? [])
        yearFrom = f.yearFrom.map { String($0) } ?? ""
        yearTo   = f.yearTo.map   { String($0) } ?? ""
    }
}
