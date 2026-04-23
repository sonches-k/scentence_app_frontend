import Foundation

final class AuthState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    private(set) var token: String?
    private(set) var refreshToken: String?

    init() {
        token        = KeychainService.shared.getToken()
        refreshToken = KeychainService.shared.getRefreshToken()
        isAuthenticated = token != nil

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForceSignOut),
            name: .forceSignOut,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTokenRefreshed(_:)),
            name: .tokenRefreshed,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Actions

    func signIn(token: String, refreshToken: String, user: User? = nil) {
        KeychainService.shared.saveToken(token)
        KeychainService.shared.saveRefreshToken(refreshToken)
        self.token        = token
        self.refreshToken = refreshToken
        self.currentUser  = user
        self.isAuthenticated = true
    }

    func signOut() {
        KeychainService.shared.deleteAllTokens()
        token        = nil
        refreshToken = nil
        currentUser  = nil
        isAuthenticated = false
    }

    func updateUser(_ user: User) {
        currentUser = user
    }

    // MARK: - Notification handlers

    @objc private func handleForceSignOut() {
        DispatchQueue.main.async { self.signOut() }
    }

    @objc private func handleTokenRefreshed(_ notification: Notification) {
        guard let newToken = notification.object as? String else { return }
        DispatchQueue.main.async {
            self.token = newToken
        }
    }
}
