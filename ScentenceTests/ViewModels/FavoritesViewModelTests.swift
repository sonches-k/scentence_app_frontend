import XCTest
@testable import Scentence

@MainActor
final class FavoritesViewModelTests: XCTestCase {

    private func makeFavorite(id: Int, name: String = "Test") -> FavoritePerfume {
        FavoritePerfume(
            id: id, name: name, brand: "Brand",
            imageUrl: nil, sourceUrl: nil,
            family: "Woody", gender: "unisex",
            category: nil, reviewSummary: nil,
            topNotes: [], middleNotes: [], baseNotes: []
        )
    }

    // MARK: - load

    func test_load_success_populates_favorites() async {
        let mock = MockAPIService()
        mock.getFavoritesResult = .success([makeFavorite(id: 1), makeFavorite(id: 2)])

        let vm = FavoritesViewModel(api: mock)
        await vm.load(token: "token")

        XCTAssertEqual(vm.favorites.count, 2)
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(mock.getFavoritesCallCount, 1)
    }

    func test_load_reverses_order() async {
        // Бэкенд отдаёт по дате добавления; мы разворачиваем для отображения новых сверху
        let mock = MockAPIService()
        mock.getFavoritesResult = .success([makeFavorite(id: 1), makeFavorite(id: 2), makeFavorite(id: 3)])

        let vm = FavoritesViewModel(api: mock)
        await vm.load(token: "token")

        XCTAssertEqual(vm.favorites.map(\.id), [3, 2, 1])
    }

    func test_load_error_sets_error_message() async {
        let mock = MockAPIService()
        mock.getFavoritesResult = .failure(MockAPIService.MockError.testError)

        let vm = FavoritesViewModel(api: mock)
        await vm.load(token: "token")

        XCTAssertTrue(vm.favorites.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_load_success_clears_error_message() async {
        let mock = MockAPIService()
        mock.getFavoritesResult = .failure(MockAPIService.MockError.testError)

        let vm = FavoritesViewModel(api: mock)
        await vm.load(token: "token")
        XCTAssertNotNil(vm.errorMessage)

        mock.getFavoritesResult = .success([makeFavorite(id: 1)])
        await vm.load(token: "token")

        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.favorites.count, 1)
    }

    func test_load_sets_loading_flag() async {
        let mock = MockAPIService()
        mock.getFavoritesResult = .success([])

        let vm = FavoritesViewModel(api: mock)
        XCTAssertFalse(vm.isLoading)
        await vm.load(token: "token")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - removeFavorite

    func test_remove_favorite_removes_from_local_array() async {
        let mock = MockAPIService()
        mock.getFavoritesResult = .success([makeFavorite(id: 1), makeFavorite(id: 2), makeFavorite(id: 3)])
        mock.removeFavoriteResult = .success(MessageResponse(message: "removed"))

        let vm = FavoritesViewModel(api: mock)
        await vm.load(token: "token")
        await vm.removeFavorite(perfumeId: 2, token: "token")

        XCTAssertEqual(vm.favorites.count, 2)
        XCTAssertFalse(vm.favorites.contains { $0.id == 2 })
        XCTAssertEqual(mock.removeFavoriteCallCount, 1)
    }

    func test_remove_favorite_removes_locally_even_on_api_error() async {
        let mock = MockAPIService()
        mock.getFavoritesResult = .success([makeFavorite(id: 1), makeFavorite(id: 2)])
        mock.removeFavoriteResult = .failure(MockAPIService.MockError.testError)

        let vm = FavoritesViewModel(api: mock)
        await vm.load(token: "token")
        await vm.removeFavorite(perfumeId: 1, token: "token")

        // Оптимистичное удаление — убираем из UI независимо от ответа API
        XCTAssertEqual(vm.favorites.count, 1)
        XCTAssertFalse(vm.favorites.contains { $0.id == 1 })
    }

    func test_remove_nonexistent_favorite_leaves_array_unchanged() async {
        let mock = MockAPIService()
        mock.getFavoritesResult = .success([makeFavorite(id: 1)])
        mock.removeFavoriteResult = .success(MessageResponse(message: "ok"))

        let vm = FavoritesViewModel(api: mock)
        await vm.load(token: "token")
        await vm.removeFavorite(perfumeId: 99, token: "token")

        XCTAssertEqual(vm.favorites.count, 1)
    }
}
