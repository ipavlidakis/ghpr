import Foundation
import Security

/// A failed Security framework call, described by operation and `OSStatus`.
package struct KeychainError: Error, CustomStringConvertible {
    package let operation: String
    package let status: OSStatus

    package init(operation: String, status: OSStatus) {
        self.operation = operation
        self.status = status
    }

    package var description: String {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        return "Keychain \(operation) failed: \(message)"
    }
}
