import Foundation

/// Everything needed to represent one file's diff.
package struct FileDiff: Sendable, Equatable {
    /// The file's current path (the pre-deletion path for deleted files).
    package let path: String
    package let status: FileDiffStatus
    package let hunks: [DiffHunk]
    package let isBinary: Bool
    private let additionCount: Int
    private let deletionCount: Int
    private let renderedLineCount: Int

    package init(path: String, status: FileDiffStatus, hunks: [DiffHunk], isBinary: Bool = false) {
        self.path = path
        self.status = status
        self.hunks = hunks
        self.isBinary = isBinary
        additionCount = hunks.reduce(0) { $0 + $1.lines.count(where: { $0.kind == .addition }) }
        deletionCount = hunks.reduce(0) { $0 + $1.lines.count(where: { $0.kind == .deletion }) }
        renderedLineCount = hunks.reduce(0) { $0 + $1.lines.count }
    }

    /// Lowercased file extension, used to pick a syntax highlighting grammar.
    package var languageHint: String? {
        let ext = (path as NSString).pathExtension.lowercased()
        return ext.isEmpty ? nil : ext
    }

    package var additions: Int {
        additionCount
    }

    package var deletions: Int {
        deletionCount
    }

    package var renderedLines: Int {
        renderedLineCount
    }
}
