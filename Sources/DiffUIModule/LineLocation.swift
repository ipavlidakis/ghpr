import Foundation

/// Addresses one line within a file diff: hunk index plus line index inside it.
package struct LineLocation: Sendable, Hashable {
    package let hunk: Int
    package let line: Int

    package init(hunk: Int, line: Int) {
        self.hunk = hunk
        self.line = line
    }
}
