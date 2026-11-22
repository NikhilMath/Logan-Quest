import Foundation
import Security

/// A few small values saved in the iPhone's keychain. Unlike UserDefaults, the keychain keeps
/// them when the app is deleted, so someone who deletes Logan Quest and downloads it again
/// gets their progress and sign-in back. Like UserDefaults, they move to a new iPhone set up
/// from a backup of this one.
struct Keychain {
    /// Keeps these items apart from any other keychain items the app might save.
    let service: String

    static let standard = Keychain(service: Bundle.main.bundleIdentifier ?? "com.nikhilmath.loganquest")

    func data(forKey key: String) -> Data? {
        var query = itemQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Saves the value, or removes it when it's nil.
    func set(_ data: Data?, forKey key: String) {
        let query = itemQuery(key)
        guard let data else {
            SecItemDelete(query as CFDictionary)
            return
        }
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
        }
    }

    func string(forKey key: String) -> String? {
        data(forKey: key).flatMap { String(data: $0, encoding: .utf8) }
    }

    func set(_ string: String?, forKey key: String) {
        set(string.map { Data($0.utf8) }, forKey: key)
    }

    private func itemQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
