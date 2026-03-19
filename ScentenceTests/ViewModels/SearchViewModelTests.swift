import XCTest
@testable import Scentence

@MainActor
final class SearchViewModelTests: XCTestCase {

    private func makeResponse(totalFound: Int = 1) -> SearchResponse {
        SearchResponse(
            query: "тест",
            notePyramid: NotePyramid(top: ["Бергамот"], middle: [], base: []),
            explanation: "пояснение",
            perfumes: [
                PerfumeWithRelevance(
                    id: 1, name: "Test", brand: "Brand",
                    imageUrl: nil, sourceUrl: nil,
                    family: "Woody", gender: "unisex",
                    topNotes: ["Бергамот"], middleNotes: [],
                    baseNotes: ["Мускус"], relevance: 0.85
                )
            ],
            filtersApplied: nil,
            totalFound: totalFound
        )
    }

    // MARK: - Тесты

    func test_search_success() async {
        let mock = MockAPIService()
        mock.searchResult = .success(makeResponse())

        let vm = SearchViewModel(api: mock)
        vm.queryText = "тёплый аромат"
        await vm.search(token: nil)

        XCTAssertNotNil(vm.searchResponse)
        XCTAssertEqual(vm.searchResponse?.perfumes.count, 1)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(mock.searchCallCount, 1)
    }

    func test_search_error() async {
        let mock = MockAPIService()
        mock.searchResult = .failure(MockAPIService.MockError.testError)

        let vm = SearchViewModel(api: mock)
        vm.queryText = "тёплый аромат"
        await vm.search(token: nil)

        XCTAssertNil(vm.searchResponse)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func test_search_clears_previous_error() async {
        let mock = MockAPIService()

        let vm = SearchViewModel(api: mock)
        vm.queryText = "тёплый аромат"

        // Первый вызов — ошибка
        mock.searchResult = .failure(MockAPIService.MockError.testError)
        await vm.search(token: nil)
        XCTAssertNotNil(vm.errorMessage)

        // Второй вызов — успех
        mock.searchResult = .success(makeResponse())
        await vm.search(token: nil)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNotNil(vm.searchResponse)
    }

    func test_search_short_query_shows_error() async {
        let mock = MockAPIService()
        let vm = SearchViewModel(api: mock)
        vm.queryText = "ab"

        await vm.search(token: nil)

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(mock.searchCallCount, 0)
    }

    func test_clear_resets_state() {
        let vm = SearchViewModel()
        vm.queryText = "test"
        vm.errorMessage = "error"

        vm.clear()

        XCTAssertEqual(vm.queryText, "")
        XCTAssertNil(vm.searchResponse)
        XCTAssertNil(vm.errorMessage)
    }
}
