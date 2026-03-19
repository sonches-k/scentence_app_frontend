import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let tokenKey = "com.scentence.authToken"
    private init() {}

    // MARK: - Public

    func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        deleteToken()
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String:   data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      tokenKey,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
