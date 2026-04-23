import Foundation
import UIKit

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
    @Published var resendCountdown: Int = 0
    @Published var showSuccessSparkle: Bool = false

    private let api: APIServiceProtocol
    private var countdownTask: Task<Void, Never>?

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
            startResendTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startResendTimer() {
        countdownTask?.cancel()
        resendCountdown = 60
        countdownTask = Task { [weak self] in
            while let self, self.resendCountdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                self.resendCountdown -= 1
            }
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showSuccessSparkle = true
            try? await Task.sleep(for: .milliseconds(500))
            authState.signIn(
                token: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken,
                user: user
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func backToEmail() {
        countdownTask?.cancel()
        resendCountdown = 0
        step = .email
        code = ""
        errorMessage = nil
        successMessage = nil
    }

    func resendCode() async {
        guard resendCountdown == 0 else { return }
        code = ""
        errorMessage = nil
        successMessage = nil
        await requestCode()
    }
}
