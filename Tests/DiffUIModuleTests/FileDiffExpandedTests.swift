import Foundation
import Testing
import DiffUIModule

/// Verifies full-context expansion against the new-side file content.
@Suite("FileDiff expansion")
struct FileDiffExpandedTests {
    @Test("expansion fills context and keeps change lines with consistent numbering")
    func expansion() {
        // Old file: a, OLD, c, d — new file: a, NEW, c, d, e
        let file = FileDiff(
            path: "Example.swift",
            status: .modified,
            hunks: [
                DiffHunk(header: "@@ -1,3 +1,3 @@", oldStart: 1, oldCount: 3, newStart: 1, newCount: 3, lines: [
                    DiffLine(kind: .context, text: "a", oldLineNumber: 1, newLineNumber: 1),
                    DiffLine(kind: .deletion, text: "OLD", oldLineNumber: 2, newLineNumber: nil),
                    DiffLine(kind: .addition, text: "NEW", oldLineNumber: nil, newLineNumber: 2),
                    DiffLine(kind: .context, text: "c", oldLineNumber: 3, newLineNumber: 3),
                ])
            ]
        )

        let expanded = file.expanded(withNewFileContent: "a\nNEW\nc\nd\ne\n")

        let lines = expanded.hunks[0].lines
        #expect(lines.map(\.text) == ["a", "OLD", "NEW", "c", "d", "e"])
        #expect(lines.map(\.kind) == [.context, .deletion, .addition, .context, .context, .context])
        // Old side numbering stays continuous around the change.
        #expect(lines.map(\.oldLineNumber) == [1, 2, nil, 3, 4, 5])
        #expect(lines.map(\.newLineNumber) == [1, nil, 2, 3, 4, 5])
        #expect(expanded.additions == 1)
        #expect(expanded.deletions == 1)
    }
}
