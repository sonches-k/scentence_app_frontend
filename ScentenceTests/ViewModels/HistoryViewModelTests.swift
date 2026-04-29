import XCTest
@testable import Scentence

@MainActor
final class HistoryViewModelTests: XCTestCase {

    private func makeEntry(id: Int, query: String = "тест") -> SearchHistoryEntry {
        SearchHistoryEntry(id: id, query: query, filters: nil, createdAt: nil)
    }

    // MARK: - load

    func test_load_success_populates_history() async {
        let mock = MockAPIService()
        mock.getHistoryResult = .success([makeEntry(id: 1), makeEntry(id: 2)])

        let vm = HistoryViewModel(api: mock)
        await vm.load(token: "token")

        XCTAssertEqual(vm.history.count, 2)
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(mock.getHistoryCallCount, 1)
    }

    func test_load_error_leaves_empty_array() async {
        let mock = MockAPIService()
        mock.getHistoryResult = .failure(MockAPIService.MockError.testError)

        let vm = HistoryViewModel(api: mock)
        await vm.load(token: "token")

        XCTAssertTrue(vm.history.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func test_load_preserves_server_order() async {
        let mock = MockAPIService()
        mock.getHistoryResult = .success([makeEntry(id: 3), makeEntry(id: 1), makeEntry(id: 2)])

        let vm = HistoryViewModel(api: mock)
        await vm.load(token: "token")

        XCTAssertEqual(vm.history.map(\.id), [3, 1, 2])
    }

    // MARK: - deleteEntry

    func test_delete_entry_removes_from_local_array() async {
        let mock = MockAPIService()
        mock.getHistoryResult = .success([makeEntry(id: 1), makeEntry(id: 2), makeEntry(id: 3)])
        mock.deleteHistoryEntryResult = .success(())

        let vm = HistoryViewModel(api: mock)
        await vm.load(token: "token")
        await vm.deleteEntry(id: 2, token: "token")

        XCTAssertEqual(vm.history.count, 2)
        XCTAssertFalse(vm.history.contains { $0.id == 2 })
        XCTAssertEqual(mock.deleteHistoryEntryCallCount, 1)
    }

    func test_delete_entry_removes_locally_even_on_api_error() async {
        let mock = MockAPIService()
        mock.getHistoryResult = .success([makeEntry(id: 1), makeEntry(id: 2)])
        mock.deleteHistoryEntryResult = .failure(MockAPIService.MockError.testError)

        let vm = HistoryViewModel(api: mock)
        await vm.load(token: "token")
        await vm.deleteEntry(id: 1, token: "token")

        XCTAssertEqual(vm.history.count, 1)
        XCTAssertFalse(vm.history.contains { $0.id == 1 })
    }

    // MARK: - clearAll

    func test_clear_all_empties_history() async {
        let mock = MockAPIService()
        mock.getHistoryResult = .success([makeEntry(id: 1), makeEntry(id: 2), makeEntry(id: 3)])
        mock.clearHistoryResult = .success(())

        let vm = HistoryViewModel(api: mock)
        await vm.load(token: "token")
        XCTAssertEqual(vm.history.count, 3)

        await vm.clearAll(token: "token")

        XCTAssertTrue(vm.history.isEmpty)
        XCTAssertEqual(mock.clearHistoryCallCount, 1)
    }

    func test_clear_all_empties_locally_even_on_api_error() async {
        let mock = MockAPIService()
        mock.getHistoryResult = .success([makeEntry(id: 1)])
        mock.clearHistoryResult = .failure(MockAPIService.MockError.testError)

        let vm = HistoryViewModel(api: mock)
        await vm.load(token: "token")
        await vm.clearAll(token: "token")

        XCTAssertTrue(vm.history.isEmpty)
    }
}
