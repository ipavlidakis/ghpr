import Foundation

/// A contiguous run of changes, as delimited by an `@@` header.
package struct DiffHunk: Sendable, Equatable {
    /// The full `@@ -old,+new @@ section` header line.
    package let header: String
    package let oldStart: Int
    package let oldCount: Int
    package let newStart: Int
    package let newCount: Int
    package let lines: [DiffLine]

    package init(header: String, oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, lines: [DiffLine]) {
        self.header = header
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.lines = lines
    }
}
