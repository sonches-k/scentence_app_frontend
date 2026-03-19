import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - State

    enum Step { case email, code }

    @Published var step: Step = .email
    @Published var email: String = ""
    @Published var code: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService.shared) {
        self.api = api
    }

    // MARK: - Actions

    func requestCode() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Введите email"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let _ = try await api.requestCode(email: email.lowercased().trimmingCharacters(in: .whitespaces))
            successMessage = "Код отправлен на \(email)"
            step = .code
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verifyCode(authState: AuthState) async {
        guard code.count == 6 else {
            errorMessage = "Код должен содержать 6 цифр"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let tokenResponse = try await api.verifyCode(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                code: code
            )
            let user = try? await api.getMe(token: tokenResponse.accessToken)
            authState.signIn(token: tokenResponse.accessToken, user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func backToEmail() {
        step = .email
        code = ""
        errorMessage = nil
        successMessage = nil
    }

    func resendCode() async {
        code = ""
        errorMessage = nil
        successMessage = nil
        await requestCode()
    }
}
