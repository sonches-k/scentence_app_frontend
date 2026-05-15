import Foundation

final class AuthState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    private(set) var token: String?
    private(set) var refreshToken: String?

    private var observers: [NSObjectProtocol] = []

    init() {
        token        = KeychainService.shared.getToken()
        refreshToken = KeychainService.shared.getRefreshToken()
        isAuthenticated = token != nil

        observers.append(
            NotificationCenter.default.addObserver(forName: .forceSignOut, object: nil, queue: .main) { [weak self] _ in
                self?.signOut()
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .tokenRefreshed, object: nil, queue: .main) { [weak self] notification in
                guard let newToken = notification.object as? String else { return }
                self?.token = newToken
            }
        )
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

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
}
