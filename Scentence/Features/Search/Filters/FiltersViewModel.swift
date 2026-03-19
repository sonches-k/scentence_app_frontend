import Foundation

@MainActor
final class FiltersViewModel: ObservableObject {
    @Published var availableGenders: [String] = []
    @Published var availableFamilies: [String] = []
    @Published var availableProductTypes: [String] = []
    @Published var availableBrands: [String] = []
    @Published var availableNotes: [String] = []

    @Published var selectedGenders: Set<String> = []
    @Published var selectedFamilies: Set<String> = []
    @Published var selectedProductTypes: Set<String> = []
    @Published var selectedBrands: Set<String> = []
    @Published var selectedNotes: Set<String> = []
    @Published var yearFrom: String = ""
    @Published var yearTo: String = ""

    @Published var isLoading: Bool = false

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    var activeCount: Int {
        var c = 0
        if !selectedGenders.isEmpty { c += 1 }
        if !selectedFamilies.isEmpty { c += 1 }
        if !selectedProductTypes.isEmpty { c += 1 }
        if !selectedBrands.isEmpty { c += 1 }
        if !selectedNotes.isEmpty { c += 1 }
        if !yearFrom.isEmpty || !yearTo.isEmpty { c += 1 }
        return c
    }

    func loadFilters(token: String?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await api.getAllFilters(token: token)
            availableGenders = response.genders
            availableFamilies = response.families
            availableProductTypes = response.productTypes
            availableBrands = response.brands
            availableNotes = response.notes
        } catch {
            // Fail silently — filters just won't show options
        }
    }

    func reset() {
        selectedGenders = []
        selectedFamilies = []
        selectedProductTypes = []
        selectedBrands = []
        selectedNotes = []
        yearFrom = ""
        yearTo = ""
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
