import Foundation

/// Parses git-style unified diffs (the format GitHub serves) into `FileDiff` values.
///
/// Lenient by design: unrecognized lines are skipped, so trailing garbage or
/// future git headers never abort a render.
package struct UnifiedDiffParser: Sendable {
    package init() {}

    package func parse(_ diff: String) -> [FileDiff] {
        var files: [FileDiff] = []
        var builder: FileBuilder?

        for line in diff.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("diff --git ") {
                if let finished = builder?.build() { files.append(finished) }
                builder = FileBuilder(gitHeader: line)
            } else {
                builder?.consume(line)
            }
        }
        if let finished = builder?.build() { files.append(finished) }
        return files
    }

    /// Accumulates one file section of the diff.
    private struct FileBuilder {
        private let gitHeader: Substring
        private var oldPath: String?
        private var newPath: String?
        private var renamedFrom: String?
        private var isNew = false
        private var isDeleted = false
        private var isBinary = false
        private var hunks: [DiffHunk] = []
        private var currentHunk: HunkBuilder?

        init(gitHeader: Substring) {
            self.gitHeader = gitHeader
        }

        mutating func consume(_ line: Substring) {
            if line.hasPrefix("@@") {
                finishHunk()
                currentHunk = HunkBuilder(headerLine: line)
            } else if let hunk = currentHunk, !hunk.isComplete {
                currentHunk?.consume(line)
            } else if line.hasPrefix("--- ") {
                oldPath = Self.path(from: line.dropFirst(4))
            } else if line.hasPrefix("+++ ") {
                newPath = Self.path(from: line.dropFirst(4))
            } else if line.hasPrefix("new file mode") {
                isNew = true
            } else if line.hasPrefix("deleted file mode") {
                isDeleted = true
            } else if line.hasPrefix("rename from ") {
                renamedFrom = String(line.dropFirst("rename from ".count))
            } else if line.hasPrefix("rename to ") {
                newPath = String(line.dropFirst("rename to ".count))
            } else if line.hasPrefix("Binary files ") || line.hasPrefix("GIT binary patch") {
                isBinary = true
            }
        }

        mutating func build() -> FileDiff? {
            finishHunk()
            guard let path = newPath ?? oldPath ?? Self.pathFromGitHeader(gitHeader) else { return nil }

            let status: FileDiffStatus =
                if isNew { .added }
                else if isDeleted { .deleted }
                else if let renamedFrom { .renamed(from: renamedFrom) }
                else { .modified }

            return FileDiff(path: path, status: status, hunks: hunks, isBinary: isBinary)
        }

        private mutating func finishHunk() {
            if let hunk = currentHunk?.build() { hunks.append(hunk) }
            currentHunk = nil
        }

        /// Resolves `a/path`, `b/path`, or `/dev/null` from a `---`/`+++` header.
        private static func path(from raw: Substring) -> String? {
            // git terminates paths containing spaces with a tab.
            var raw = raw
            while raw.hasSuffix("\t") { raw = raw.dropLast() }

            if raw == "/dev/null" { return nil }
            if raw.hasPrefix("a/") || raw.hasPrefix("b/") { return String(raw.dropFirst(2)) }
            return String(raw)
        }

        /// Last-resort path extraction (binary files and 100%-similarity renames
        /// have no `---`/`+++` lines): `diff --git a/path b/path`.
        private static func pathFromGitHeader(_ header: Substring) -> String? {
            let payload = header.dropFirst("diff --git ".count)
            guard let separator = payload.range(of: " b/"), payload.hasPrefix("a/") else { return nil }
            return String(payload[separator.upperBound...])
        }
    }

    /// Accumulates one `@@` hunk, tracking per-side line numbers.
    private struct HunkBuilder {
        private let header: String
        private let oldStart: Int
        private let oldCount: Int
        private let newStart: Int
        private let newCount: Int
        private var lines: [DiffLine] = []
        private var oldLine: Int
        private var newLine: Int

        init?(headerLine: Substring) {
            let pattern = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/
            guard let match = try? pattern.firstMatch(in: headerLine),
                  let oldStart = Int(match.1),
                  let newStart = Int(match.3)
            else { return nil }

            header = String(headerLine)
            self.oldStart = oldStart
            self.newStart = newStart
            oldCount = match.2.flatMap { Int($0) } ?? 1
            newCount = match.4.flatMap { Int($0) } ?? 1
            oldLine = oldStart
            newLine = newStart
        }

        /// True once both sides have produced every line the header promised,
        /// so trailing blank lines never leak into the hunk.
        var isComplete: Bool {
            oldLine >= oldStart + oldCount && newLine >= newStart + newCount
        }

        mutating func consume(_ line: Substring) {
            switch line.first {
            case "+":
                lines.append(DiffLine(kind: .addition, text: String(line.dropFirst()), oldLineNumber: nil, newLineNumber: newLine))
                newLine += 1
            case "-":
                lines.append(DiffLine(kind: .deletion, text: String(line.dropFirst()), oldLineNumber: oldLine, newLineNumber: nil))
                oldLine += 1
            case " ", nil:
                // git emits genuinely empty context lines without the leading space.
                lines.append(DiffLine(kind: .context, text: String(line.dropFirst(line.isEmpty ? 0 : 1)), oldLineNumber: oldLine, newLineNumber: newLine))
                oldLine += 1
                newLine += 1
            default:
                // "\ No newline at end of file" and anything unrecognized.
                break
            }
        }

        func build() -> DiffHunk {
            DiffHunk(header: header, oldStart: oldStart, oldCount: oldCount, newStart: newStart, newCount: newCount, lines: lines)
        }
    }
}
