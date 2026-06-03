import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let accessGroup = "app.realvirtuality"
    private let tokenKey = "jwt_token"

    private init() {}

    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecAttrAccessGroup: accessGroup,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func loadToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecAttrAccessGroup: accessGroup,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecAttrAccessGroup: accessGroup
        ]
        SecItemDelete(query as CFDictionary)
    }
}
