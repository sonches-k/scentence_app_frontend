import Foundation

final class AuthState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?

    private(set) var token: String?

    init() {
        token = KeychainService.shared.getToken()
        isAuthenticated = token != nil
    }

    func signIn(token: String, user: User? = nil) {
        KeychainService.shared.saveToken(token)
        self.token = token
        self.currentUser = user
        self.isAuthenticated = true
    }

    func signOut() {
        KeychainService.shared.deleteToken()
        self.token = nil
        self.currentUser = nil
        self.isAuthenticated = false
    }

    func updateUser(_ user: User) {
        self.currentUser = user
    }
}
