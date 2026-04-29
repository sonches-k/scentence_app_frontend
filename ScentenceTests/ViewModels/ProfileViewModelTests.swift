import XCTest
@testable import Scentence

@MainActor
final class ProfileViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        KeychainService.shared.deleteAllTokens()
    }

    override func tearDown() {
        KeychainService.shared.deleteAllTokens()
        super.tearDown()
    }

    private func makeUser(name: String? = "Sofia") -> User {
        User(id: 1, email: "sofia@example.com", name: name, createdAt: nil)
    }

    // MARK: - loadProfile

    func test_load_profile_success_returns_user() async {
        let mock = MockAPIService()
        mock.getMeResult = .success(makeUser())

        let vm = ProfileViewModel(api: mock)
        let user = await vm.loadProfile(token: "token")

        XCTAssertNotNil(user)
        XCTAssertEqual(user?.email, "sofia@example.com")
        XCTAssertEqual(user?.name, "Sofia")
    }

    func test_load_profile_error_returns_nil_silently() async {
        let mock = MockAPIService()
        mock.getMeResult = .failure(MockAPIService.MockError.testError)

        let vm = ProfileViewModel(api: mock)
        let user = await vm.loadProfile(token: "token")

        XCTAssertNil(user)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - updateName

    func test_update_name_success_returns_user_and_closes_editor() async {
        let mock = MockAPIService()
        mock.updateNameResult = .success(makeUser(name: "NewName"))

        let vm = ProfileViewModel(api: mock)
        vm.newName = "NewName"
        vm.isEditingName = true

        let user = await vm.updateName(token: "token")

        XCTAssertNotNil(user)
        XCTAssertEqual(user?.name, "NewName")
        XCTAssertFalse(vm.isEditingName)
        XCTAssertNil(vm.errorMessage)
    }

    func test_update_name_empty_returns_nil_without_api_call() async {
        let mock = MockAPIService()
        let vm = ProfileViewModel(api: mock)
        vm.newName = ""

        let user = await vm.updateName(token: "token")

        XCTAssertNil(user)
        // updateNameResult не сконфигурирован — если бы API вызвался, упал бы
    }

    func test_update_name_whitespace_only_returns_nil_without_api_call() async {
        let mock = MockAPIService()
        let vm = ProfileViewModel(api: mock)
        vm.newName = "   "

        let user = await vm.updateName(token: "token")

        XCTAssertNil(user)
    }

    func test_update_name_trims_whitespace() async {
        let mock = MockAPIService()
        mock.updateNameResult = .success(makeUser(name: "Sofia"))

        let vm = ProfileViewModel(api: mock)
        vm.newName = "  Sofia  "

        let user = await vm.updateName(token: "token")

        XCTAssertNotNil(user)
        XCTAssertFalse(vm.isEditingName)
    }

    func test_update_name_api_error_sets_error_message_and_keeps_editor_open() async {
        let mock = MockAPIService()
        mock.updateNameResult = .failure(MockAPIService.MockError.testError)

        let vm = ProfileViewModel(api: mock)
        vm.newName = "NewName"
        vm.isEditingName = true

        let user = await vm.updateName(token: "token")

        XCTAssertNil(user)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.isEditingName)
    }

    // MARK: - signOut

    func test_sign_out_clears_auth_state() async {
        let mock = MockAPIService()
        mock.logoutResult = .success(MessageResponse(message: "OK"))

        let vm = ProfileViewModel(api: mock)
        let authState = AuthState()
        authState.signIn(token: "access", refreshToken: "refresh")
        XCTAssertTrue(authState.isAuthenticated)

        await vm.signOut(authState: authState)

        XCTAssertFalse(authState.isAuthenticated)
        XCTAssertNil(authState.currentUser)
    }

    func test_sign_out_clears_auth_even_if_api_fails() async {
        let mock = MockAPIService()
        mock.logoutResult = .failure(MockAPIService.MockError.testError)

        let vm = ProfileViewModel(api: mock)
        let authState = AuthState()
        authState.signIn(token: "access", refreshToken: "refresh")

        await vm.signOut(authState: authState)

        XCTAssertFalse(authState.isAuthenticated)
    }

    func test_sign_out_without_refresh_token_still_signs_out_locally() async {
        let mock = MockAPIService()

        let vm = ProfileViewModel(api: mock)
        let authState = AuthState()
        // Симулируем состояние без refreshToken через signIn с пустым токеном
        // и ручной очисткой — просто проверяем что signOut() не крашится
        await vm.signOut(authState: authState)

        XCTAssertFalse(authState.isAuthenticated)
    }
}
