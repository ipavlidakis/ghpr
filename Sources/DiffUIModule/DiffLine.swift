import Foundation

/// One line of a diff hunk, with its position on each side.
package struct DiffLine: Sendable, Equatable {
    package let kind: DiffLineKind
    /// Line content without the leading `+`, `-`, or space marker.
    package let text: String
    /// `nil` for additions.
    package let oldLineNumber: Int?
    /// `nil` for deletions.
    package let newLineNumber: Int?

    package init(kind: DiffLineKind, text: String, oldLineNumber: Int?, newLineNumber: Int?) {
        self.kind = kind
        self.text = text
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
    }
}
