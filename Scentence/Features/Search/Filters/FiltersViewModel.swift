import Foundation

@MainActor
final class FiltersViewModel: ObservableObject {

    // MARK: - Static filter options (loaded once)

    @Published var availableGenders: [String] = []
    @Published var availableFamilies: [String] = []
    @Published var availableProductTypes: [String] = []
    @Published var availableCategories: [String] = []

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
    @Published var selectedCategories: Set<String> = []
    @Published var selectedBrands: Set<String> = []
    @Published var selectedNotes: Set<String> = []
    @Published var yearFrom: String = ""
    @Published var yearTo: String = ""

    @Published var isLoading: Bool = false
    @Published var filterError: String?

    private let api: APIServiceProtocol
    private var brandSearchTask: Task<Void, Never>?
    private var noteSearchTask: Task<Void, Never>?
    private var token: String?

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    var activeCount: Int {
        var c = 0
        if !selectedGenders.isEmpty      { c += 1 }
        if !selectedFamilies.isEmpty     { c += 1 }
        if !selectedProductTypes.isEmpty { c += 1 }
        if !selectedCategories.isEmpty   { c += 1 }
        if !selectedBrands.isEmpty       { c += 1 }
        if !selectedNotes.isEmpty        { c += 1 }
        if !yearFrom.isEmpty || !yearTo.isEmpty { c += 1 }
        return c
    }

    var activeFilterChips: [String] {
        var chips: [String] = []
        chips += selectedGenders.sorted()
        chips += selectedFamilies.sorted()
        chips += selectedProductTypes.sorted()
        chips += selectedCategories.sorted()
        chips += selectedBrands.sorted().prefix(2)
        chips += selectedNotes.sorted().prefix(2)
        if !yearFrom.isEmpty, !yearTo.isEmpty { chips.append("\(yearFrom)–\(yearTo) г.") }
        else if !yearFrom.isEmpty { chips.append("от \(yearFrom) г.") }
        else if !yearTo.isEmpty   { chips.append("до \(yearTo) г.") }
        return chips
    }

    // MARK: - Load

    func loadFilters(token: String?) async {
        self.token = token
        filterError = nil
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
            availableCategories   = Self.sortedCategories(filters.categories)
            brandSuggestions      = brands
            noteSuggestions       = notes
        } catch {
            filterError = "Не удалось загрузить фильтры"
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
        } catch {}
    }

    private func fetchNoteSuggestions(q: String) async {
        isNoteLoading = true
        defer { isNoteLoading = false }
        do {
            noteSuggestions = try await api.suggestNotes(q: q, token: token)
        } catch {}
    }

    func retryLoadFilters() async {
        await loadFilters(token: token)
    }

    func sanitizeYear(_ value: String) -> String {
        let digits = String(value.filter { $0.isNumber }.prefix(4))
        guard digits.count == 4, let year = Int(digits) else { return digits }
        return String(min(max(year, 1900), 2030))
    }

    // MARK: - Reset / Apply / Build

    func reset() {
        selectedGenders      = []
        selectedFamilies     = []
        selectedProductTypes = []
        selectedCategories   = []
        selectedBrands       = []
        selectedNotes        = []
        yearFrom             = ""
        yearTo               = ""
        brandSearchQuery     = ""
        noteSearchQuery      = ""
    }

    func buildFilters() -> SearchFilters? {
        if let f = Int(yearFrom), let t = Int(yearTo), f > t {
            swap(&yearFrom, &yearTo)
        }
        let from = Int(yearFrom)
        let to = Int(yearTo)

        let filters = SearchFilters(
            genders:      selectedGenders.isEmpty      ? nil : Array(selectedGenders).sorted(),
            families:     selectedFamilies.isEmpty     ? nil : Array(selectedFamilies).sorted(),
            productTypes: selectedProductTypes.isEmpty ? nil : Array(selectedProductTypes).sorted(),
            categories:   selectedCategories.isEmpty   ? nil : Array(selectedCategories).sorted(),
            brands:       selectedBrands.isEmpty       ? nil : Array(selectedBrands).sorted(),
            notes:        selectedNotes.isEmpty        ? nil : Array(selectedNotes).sorted(),
            yearFrom:     from,
            yearTo:       to
        )
        return filters.isEmpty ? nil : filters
    }

    // MARK: - Helpers

    /// Сортирует категории по популярности; неизвестные — в конец по алфавиту.
    private static func sortedCategories(_ categories: [String]) -> [String] {
        let order = ["Люкс", "Нишевая", "Восточная", "Масляная"]
        return categories.sorted { a, b in
            let ia = order.firstIndex(of: a) ?? Int.max
            let ib = order.firstIndex(of: b) ?? Int.max
            return ia == ib ? a < b : ia < ib
        }
    }

    func apply(from existing: SearchFilters?) {
        guard let f = existing else { reset(); return }
        selectedGenders      = Set(f.genders ?? [])
        selectedFamilies     = Set(f.families ?? [])
        selectedProductTypes = Set(f.productTypes ?? [])
        selectedCategories   = Set(f.categories ?? [])
        selectedBrands       = Set(f.brands ?? [])
        selectedNotes        = Set(f.notes ?? [])
        yearFrom = f.yearFrom.map { String($0) } ?? ""
        yearTo   = f.yearTo.map   { String($0) } ?? ""
    }
}
