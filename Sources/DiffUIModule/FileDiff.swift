import Foundation

/// Everything needed to render one file's diff. The module's own input
/// format — deliberately unaware of GitHub or any other diff producer.
package struct FileDiff: Sendable, Equatable {
    /// The file's current path (the pre-deletion path for deleted files).
    package let path: String
    package let status: FileDiffStatus
    package let hunks: [DiffHunk]
    package let isBinary: Bool

    package init(path: String, status: FileDiffStatus, hunks: [DiffHunk], isBinary: Bool = false) {
        self.path = path
        self.status = status
        self.hunks = hunks
        self.isBinary = isBinary
    }

    /// Lowercased file extension, used to pick a syntax highlighting grammar.
    package var languageHint: String? {
        let ext = (path as NSString).pathExtension.lowercased()
        return ext.isEmpty ? nil : ext
    }

    package var additions: Int {
        hunks.reduce(0) { $0 + $1.lines.count(where: { $0.kind == .addition }) }
    }

    package var deletions: Int {
        hunks.reduce(0) { $0 + $1.lines.count(where: { $0.kind == .deletion }) }
    }
}
