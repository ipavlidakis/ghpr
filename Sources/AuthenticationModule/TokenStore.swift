import Foundation
import Security

/// Persistent storage for the user's GitHub token.
package protocol TokenStore: Sendable {
    func read() async throws -> String?
    func write(_ token: String) async throws
    /// Returns `true` when a stored token was actually removed.
    @discardableResult
    func delete() async throws -> Bool
}

/// Stores the token as a generic password in the macOS Keychain.
package actor KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    package init(service: String = "ghpr", account: String = "github-token") {
        self.service = service
        self.account = account
    }

    package func read() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError(operation: "read", status: status)
        }
    }

    package func write(_ token: String) throws {
        let data = Data(token.utf8)

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let update = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError(operation: "update", status: updateStatus)
            }
        default:
            throw KeychainError(operation: "write", status: status)
        }
    }

    @discardableResult
    package func delete() throws -> Bool {
        let status = SecItemDelete(baseQuery as CFDictionary)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            throw KeychainError(operation: "delete", status: status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

package struct KeychainError: Error, CustomStringConvertible {
    package let operation: String
    package let status: OSStatus

    package var description: String {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        return "Keychain \(operation) failed: \(message)"
    }
}
