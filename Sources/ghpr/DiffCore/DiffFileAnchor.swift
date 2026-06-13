import Foundation

/// Addresses a diff line across files: path plus side-and-line anchor.
package struct DiffFileAnchor: Sendable, Hashable {
    package let path: String
    package let anchor: DiffLineAnchor

    package init(path: String, anchor: DiffLineAnchor) {
        self.path = path
        self.anchor = anchor
    }
}
