import Foundation
import Security

/// Simple helper for Keychain access
final class KeychainHelper {
  static let shared = KeychainHelper()

  private let service = "com.jobtrigger.backend"

  private init() {}

  func save(_ value: String, for key: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]

    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
  }

  func retrieve(for key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess, let data = dataTypeRef as? Data {
      return String(data: data, encoding: .utf8)
    }
    return nil
  }

  func delete(for key: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]
    SecItemDelete(query as CFDictionary)
  }
}
