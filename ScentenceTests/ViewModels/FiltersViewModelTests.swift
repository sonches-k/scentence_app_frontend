import XCTest
@testable import Scentence

@MainActor
final class FiltersViewModelTests: XCTestCase {

    private func makeFiltersResponse(
        categories: [String] = ["Люкс", "Нишевая"]
    ) -> AllFiltersResponse {
        AllFiltersResponse(
            genders: ["male", "female", "unisex"],
            families: ["Woody", "Oriental", "Floral"],
            productTypes: ["EDP", "EDT"],
            categories: categories
        )
    }

    // MARK: - loadFilters

    func test_load_filters_populates_all_options() async {
        let mock = MockAPIService()
        mock.getAllFiltersResult = .success(makeFiltersResponse())
        mock.suggestBrandsResult = .success(["Dior", "Chanel"])
        mock.suggestNotesResult = .success(["Rose", "Vanilla"])

        let vm = FiltersViewModel(api: mock)
        await vm.loadFilters(token: nil)

        XCTAssertEqual(vm.availableGenders, ["male", "female", "unisex"])
        XCTAssertEqual(vm.availableFamilies, ["Woody", "Oriental", "Floral"])
        XCTAssertEqual(vm.availableProductTypes, ["EDP", "EDT"])
        XCTAssertEqual(vm.brandSuggestions, ["Dior", "Chanel"])
        XCTAssertEqual(vm.noteSuggestions, ["Rose", "Vanilla"])
        XCTAssertFalse(vm.isLoading)
    }

    func test_load_filters_sorts_categories_by_popularity() async {
        let mock = MockAPIService()
        mock.getAllFiltersResult = .success(makeFiltersResponse(
            categories: ["Масляная", "Нишевая", "Люкс", "Восточная"]
        ))
        mock.suggestBrandsResult = .success([])
        mock.suggestNotesResult = .success([])

        let vm = FiltersViewModel(api: mock)
        await vm.loadFilters(token: nil)

        XCTAssertEqual(vm.availableCategories, ["Люкс", "Нишевая", "Восточная", "Масляная"])
    }

    func test_load_filters_unknown_categories_go_to_end_alphabetically() async {
        let mock = MockAPIService()
        mock.getAllFiltersResult = .success(makeFiltersResponse(
            categories: ["Новая", "Люкс", "Аква"]
        ))
        mock.suggestBrandsResult = .success([])
        mock.suggestNotesResult = .success([])

        let vm = FiltersViewModel(api: mock)
        await vm.loadFilters(token: nil)

        XCTAssertEqual(vm.availableCategories.first, "Люкс")
        XCTAssertEqual(vm.availableCategories.last, "Новая")
        XCTAssertTrue(vm.availableCategories.contains("Аква"))
    }

    func test_load_filters_error_sets_filter_error() async {
        let mock = MockAPIService()
        mock.getAllFiltersResult = .failure(MockAPIService.MockError.testError)
        mock.suggestBrandsResult = .failure(MockAPIService.MockError.testError)
        mock.suggestNotesResult = .failure(MockAPIService.MockError.testError)

        let vm = FiltersViewModel(api: mock)
        await vm.loadFilters(token: nil)

        XCTAssertTrue(vm.availableGenders.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.filterError)
    }

    func test_load_filters_success_clears_filter_error() async {
        let mock = MockAPIService()
        mock.getAllFiltersResult = .failure(MockAPIService.MockError.testError)
        mock.suggestBrandsResult = .failure(MockAPIService.MockError.testError)
        mock.suggestNotesResult = .failure(MockAPIService.MockError.testError)

        let vm = FiltersViewModel(api: mock)
        await vm.loadFilters(token: nil)
        XCTAssertNotNil(vm.filterError)

        mock.getAllFiltersResult = .success(makeFiltersResponse())
        mock.suggestBrandsResult = .success([])
        mock.suggestNotesResult = .success([])
        await vm.loadFilters(token: nil)

        XCTAssertNil(vm.filterError)
    }

    // MARK: - activeCount

    func test_active_count_zero_when_nothing_selected() {
        let vm = FiltersViewModel()
        XCTAssertEqual(vm.activeCount, 0)
    }

    func test_active_count_increments_per_group() {
        let vm = FiltersViewModel()
        vm.selectedGenders = ["male"]
        vm.selectedFamilies = ["Woody", "Oriental"]
        vm.selectedCategories = ["Люкс"]
        vm.yearFrom = "2010"

        // Каждая группа считается как 1, независимо от числа значений
        XCTAssertEqual(vm.activeCount, 4)
    }

    func test_active_count_year_group_counts_once() {
        let vm = FiltersViewModel()
        vm.yearFrom = "2000"
        vm.yearTo = "2023"

        XCTAssertEqual(vm.activeCount, 1)
    }

    // MARK: - activeFilterChips

    func test_active_filter_chips_contains_all_selected() {
        let vm = FiltersViewModel()
        vm.selectedGenders = ["male"]
        vm.selectedFamilies = ["Woody"]
        vm.selectedCategories = ["Люкс"]
        vm.selectedBrands = ["Dior", "Chanel", "Guerlain"]
        vm.yearFrom = "2010"
        vm.yearTo = "2023"

        let chips = vm.activeFilterChips

        XCTAssertTrue(chips.contains("male"))
        XCTAssertTrue(chips.contains("Woody"))
        XCTAssertTrue(chips.contains("Люкс"))
        XCTAssertTrue(chips.contains("Dior"))
        XCTAssertTrue(chips.contains("Chanel"))
        XCTAssertFalse(chips.contains("Guerlain"))  // Бренды ограничены двумя
        XCTAssertTrue(chips.contains("2010–2023 г."))
    }

    // MARK: - buildFilters

    func test_build_filters_returns_nil_when_nothing_selected() {
        let vm = FiltersViewModel()
        XCTAssertNil(vm.buildFilters())
    }

    func test_build_filters_returns_sorted_arrays() {
        let vm = FiltersViewModel()
        vm.selectedBrands = ["Guerlain", "Chanel", "Dior"]
        vm.selectedNotes = ["Vanilla", "Rose", "Musk"]

        let filters = vm.buildFilters()

        XCTAssertEqual(filters?.brands, ["Chanel", "Dior", "Guerlain"])
        XCTAssertEqual(filters?.notes, ["Musk", "Rose", "Vanilla"])
    }

    func test_build_filters_sorted_arrays_ensure_deduplication() {
        // Одинаковые фильтры должны давать одинаковый SearchFilters независимо
        // от порядка выбора в UI — это критично для дедупликации истории поиска.
        let vm1 = FiltersViewModel()
        vm1.selectedBrands = ["Chanel", "Dior"]

        let vm2 = FiltersViewModel()
        vm2.selectedBrands = ["Dior", "Chanel"]

        XCTAssertEqual(vm1.buildFilters(), vm2.buildFilters())
    }

    func test_build_filters_includes_year_range() {
        let vm = FiltersViewModel()
        vm.yearFrom = "2005"
        vm.yearTo = "2020"

        let filters = vm.buildFilters()

        XCTAssertEqual(filters?.yearFrom, 2005)
        XCTAssertEqual(filters?.yearTo, 2020)
    }

    func test_build_filters_invalid_year_string_ignored() {
        let vm = FiltersViewModel()
        vm.yearFrom = "abc"

        XCTAssertNil(vm.buildFilters())
    }

    func test_build_filters_swaps_year_when_from_greater_than_to() {
        let vm = FiltersViewModel()
        vm.yearFrom = "2020"
        vm.yearTo = "2010"

        let filters = vm.buildFilters()

        XCTAssertEqual(filters?.yearFrom, 2010)
        XCTAssertEqual(filters?.yearTo, 2020)
        XCTAssertEqual(vm.yearFrom, "2010")
        XCTAssertEqual(vm.yearTo, "2020")
    }

    // MARK: - sanitizeYear

    func test_sanitize_year_filters_non_digits() {
        let vm = FiltersViewModel()
        XCTAssertEqual(vm.sanitizeYear("20ab"), "20")
        XCTAssertEqual(vm.sanitizeYear("abc"), "")
    }

    func test_sanitize_year_limits_to_four_digits() {
        let vm = FiltersViewModel()
        XCTAssertEqual(vm.sanitizeYear("20251999"), "2025")
    }

    func test_sanitize_year_clamps_to_valid_range() {
        let vm = FiltersViewModel()
        XCTAssertEqual(vm.sanitizeYear("0050"), "1900")
        XCTAssertEqual(vm.sanitizeYear("9999"), "2030")
        XCTAssertEqual(vm.sanitizeYear("2000"), "2000")
    }

    func test_sanitize_year_incomplete_input_not_clamped() {
        let vm = FiltersViewModel()
        XCTAssertEqual(vm.sanitizeYear("199"), "199")
        XCTAssertEqual(vm.sanitizeYear("2"), "2")
    }

    // MARK: - reset

    func test_reset_clears_all_selections() {
        let vm = FiltersViewModel()
        vm.selectedGenders = ["male"]
        vm.selectedFamilies = ["Woody"]
        vm.selectedProductTypes = ["EDP"]
        vm.selectedCategories = ["Люкс"]
        vm.selectedBrands = ["Dior"]
        vm.selectedNotes = ["Rose"]
        vm.yearFrom = "2010"
        vm.yearTo = "2023"
        vm.brandSearchQuery = "Chan"
        vm.noteSearchQuery = "Van"

        vm.reset()

        XCTAssertTrue(vm.selectedGenders.isEmpty)
        XCTAssertTrue(vm.selectedFamilies.isEmpty)
        XCTAssertTrue(vm.selectedProductTypes.isEmpty)
        XCTAssertTrue(vm.selectedCategories.isEmpty)
        XCTAssertTrue(vm.selectedBrands.isEmpty)
        XCTAssertTrue(vm.selectedNotes.isEmpty)
        XCTAssertTrue(vm.yearFrom.isEmpty)
        XCTAssertTrue(vm.yearTo.isEmpty)
        XCTAssertTrue(vm.brandSearchQuery.isEmpty)
        XCTAssertTrue(vm.noteSearchQuery.isEmpty)
        XCTAssertEqual(vm.activeCount, 0)
    }

    // MARK: - apply(from:)

    func test_apply_from_nil_resets_state() {
        let vm = FiltersViewModel()
        vm.selectedGenders = ["male"]
        vm.yearFrom = "2010"

        vm.apply(from: nil)

        XCTAssertTrue(vm.selectedGenders.isEmpty)
        XCTAssertTrue(vm.yearFrom.isEmpty)
    }

    func test_apply_from_restores_filters() {
        let filters = SearchFilters(
            genders: ["female"],
            families: ["Oriental"],
            productTypes: ["EDP"],
            categories: ["Нишевая"],
            brands: ["Chanel"],
            notes: ["Rose"],
            yearFrom: 2000,
            yearTo: 2020
        )

        let vm = FiltersViewModel()
        vm.apply(from: filters)

        XCTAssertEqual(vm.selectedGenders, ["female"])
        XCTAssertEqual(vm.selectedFamilies, ["Oriental"])
        XCTAssertEqual(vm.selectedProductTypes, ["EDP"])
        XCTAssertEqual(vm.selectedCategories, ["Нишевая"])
        XCTAssertEqual(vm.selectedBrands, ["Chanel"])
        XCTAssertEqual(vm.selectedNotes, ["Rose"])
        XCTAssertEqual(vm.yearFrom, "2000")
        XCTAssertEqual(vm.yearTo, "2020")
    }

    func test_apply_and_build_roundtrip() {
        let original = SearchFilters(
            genders: ["male"],
            families: nil,
            productTypes: ["EDP"],
            categories: ["Люкс"],
            brands: ["Dior"],
            notes: nil,
            yearFrom: 2010,
            yearTo: nil
        )

        let vm = FiltersViewModel()
        vm.apply(from: original)
        let rebuilt = vm.buildFilters()

        XCTAssertEqual(original, rebuilt)
    }
}
