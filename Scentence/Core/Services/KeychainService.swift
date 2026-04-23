import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let accessTokenKey  = "com.scentence.authToken"
    private let refreshTokenKey = "com.scentence.refreshToken"

    private init() {}

    // MARK: - Access Token

    func saveToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }

    func getToken() -> String? {
        load(forKey: accessTokenKey)
    }

    @discardableResult
    func deleteToken() -> Bool {
        delete(forKey: accessTokenKey)
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }

    func getRefreshToken() -> String? {
        load(forKey: refreshTokenKey)
    }

    @discardableResult
    func deleteRefreshToken() -> Bool {
        delete(forKey: refreshTokenKey)
    }

    // MARK: - Convenience

    func deleteAllTokens() {
        deleteToken()
        deleteRefreshToken()
    }

    // MARK: - Private helpers

    private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(forKey: key)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
