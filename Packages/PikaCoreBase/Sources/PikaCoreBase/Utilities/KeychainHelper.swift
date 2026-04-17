import Foundation
import Security

/// Thread-safe Keychain wrapper for storing sensitive values (API keys, tokens).
/// Uses kSecClassGenericPassword. Keys are stored per-device only (not iCloud Keychain).
public enum KeychainHelper {

    public enum Key: String {
        case openAIKey      = "openai_api_key"
        case anthropicKey   = "anthropic_api_key"
        case userToken      = "user_auth_token"
    }

    private static let service = "com.pikapika.app"

    /// Save or update a string value in the Keychain.
    @discardableResult
    public static func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     key.rawValue,
            kSecAttrAccessible as String:  kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Try to update first; if not found, add.
        let updateAttributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        }
        return status == errSecSuccess
    }

    /// Retrieve a string value from the Keychain. Returns nil if not found.
    public static func load(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a key from the Keychain.
    @discardableResult
    public static func delete(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check whether a key exists in the Keychain.
    public static func exists(_ key: Key) -> Bool {
        load(key) != nil
    }
}
