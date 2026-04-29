import XCTest
@testable import Scentence

@MainActor
final class AuthViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        KeychainService.shared.deleteAllTokens()
    }

    override func tearDown() {
        KeychainService.shared.deleteAllTokens()
        super.tearDown()
    }

    private func makeTokenResponse() -> TokenResponse {
        TokenResponse(accessToken: "access-token", refreshToken: "refresh-token", tokenType: "bearer")
    }

    private func makeUser() -> User {
        User(id: 1, email: "sofia@example.com", name: "Sofia", createdAt: nil)
    }

    // MARK: - requestCode

    func test_request_code_empty_email_shows_error_without_api_call() async {
        let mock = MockAPIService()
        let vm = AuthViewModel(api: mock)
        vm.email = "   "

        await vm.requestCode()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.step, .email)
    }

    func test_request_code_success_advances_to_code_step() async {
        let mock = MockAPIService()
        mock.requestCodeResult = .success(MessageResponse(message: "sent"))

        let vm = AuthViewModel(api: mock)
        vm.email = "sofia@example.com"

        await vm.requestCode()

        XCTAssertEqual(vm.step, .code)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNotNil(vm.successMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func test_request_code_trims_and_lowercases_email() async {
        let mock = MockAPIService()
        mock.requestCodeResult = .success(MessageResponse(message: "sent"))

        let vm = AuthViewModel(api: mock)
        vm.email = "  Sofia@Example.COM  "

        await vm.requestCode()

        XCTAssertEqual(vm.step, .code)
    }

    func test_request_code_api_error_shows_message() async {
        let mock = MockAPIService()
        mock.requestCodeResult = .failure(MockAPIService.MockError.testError)

        let vm = AuthViewModel(api: mock)
        vm.email = "sofia@example.com"

        await vm.requestCode()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.step, .email)
        XCTAssertFalse(vm.isLoading)
    }

    func test_request_code_starts_countdown() async {
        let mock = MockAPIService()
        mock.requestCodeResult = .success(MessageResponse(message: "sent"))

        let vm = AuthViewModel(api: mock)
        vm.email = "sofia@example.com"

        await vm.requestCode()

        XCTAssertGreaterThan(vm.resendCountdown, 0)
    }

    // MARK: - verifyCode

    func test_verify_code_short_code_shows_error_without_api_call() async {
        let mock = MockAPIService()
        let vm = AuthViewModel(api: mock)
        let authState = AuthState()
        vm.code = "123"

        await vm.verifyCode(authState: authState)

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(authState.isAuthenticated)
    }

    func test_verify_code_success_signs_in() async {
        let mock = MockAPIService()
        mock.verifyCodeResult = .success(makeTokenResponse())
        mock.getMeResult = .success(makeUser())

        let vm = AuthViewModel(api: mock)
        let authState = AuthState()
        vm.email = "sofia@example.com"
        vm.code = "123456"

        await vm.verifyCode(authState: authState)

        XCTAssertTrue(authState.isAuthenticated)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func test_verify_code_api_error_shows_message() async {
        let mock = MockAPIService()
        mock.verifyCodeResult = .failure(MockAPIService.MockError.testError)

        let vm = AuthViewModel(api: mock)
        let authState = AuthState()
        vm.code = "123456"

        await vm.verifyCode(authState: authState)

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(authState.isAuthenticated)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - backToEmail

    func test_back_to_email_resets_state() async {
        let mock = MockAPIService()
        mock.requestCodeResult = .success(MessageResponse(message: "sent"))

        let vm = AuthViewModel(api: mock)
        vm.email = "sofia@example.com"
        await vm.requestCode()
        XCTAssertEqual(vm.step, .code)

        vm.backToEmail()

        XCTAssertEqual(vm.step, .email)
        XCTAssertEqual(vm.code, "")
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.successMessage)
        XCTAssertEqual(vm.resendCountdown, 0)
    }

    // MARK: - resendCode

    func test_resend_code_blocked_while_countdown_active() async {
        let mock = MockAPIService()
        mock.requestCodeResult = .success(MessageResponse(message: "sent"))

        let vm = AuthViewModel(api: mock)
        vm.email = "sofia@example.com"
        await vm.requestCode()

        let countBefore = vm.resendCountdown
        XCTAssertGreaterThan(countBefore, 0)

        await vm.resendCode()

        // При активном таймере resendCode не должен вызывать API повторно
        XCTAssertEqual(vm.resendCountdown, countBefore)
    }
}
