import Foundation

/// A request to scroll the multi-file table to a file's header.
/// The token distinguishes repeated requests for the same path.
package struct DiffScrollTarget: Sendable, Equatable {
    package let path: String
    package let token: UUID

    package init(path: String) {
        self.path = path
        token = UUID()
    }
}
