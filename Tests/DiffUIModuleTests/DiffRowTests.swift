import Foundation
import Testing
@testable import DiffUIModule

/// Verifies row flattening and annotation row insertion.
@Suite("DiffRow")
struct DiffRowTests {
    private let file = FileDiff(
        path: "Example.swift",
        status: .modified,
        hunks: [
            DiffHunk(
                header: "@@ -1,2 +1,2 @@",
                oldStart: 1,
                oldCount: 2,
                newStart: 1,
                newCount: 2,
                lines: [
                    DiffLine(kind: .context, text: "unchanged", oldLineNumber: 1, newLineNumber: 1),
                    DiffLine(kind: .deletion, text: "old", oldLineNumber: 2, newLineNumber: nil),
                    DiffLine(kind: .addition, text: "new", oldLineNumber: nil, newLineNumber: 2),
                ]
            )
        ]
    )

    @Test("without annotations: header plus one row per line")
    func plainRows() {
        let rows = DiffRow.rows(for: file)

        #expect(rows.count == 4)
        #expect(rows.map(\.id) == [0, 1, 2, 3])
    }

    @Test("annotation rows are inserted after their anchor line")
    func annotationInsertion() {
        let rows = DiffRow.rows(for: file, annotatedAnchors: [.new(2), .old(2)])

        #expect(rows.count == 6)
        guard case .line(_, _, _, let deleted, _) = rows[2], case .annotation(_, let oldAnchor) = rows[3],
              case .line(_, _, _, let added, _) = rows[4], case .annotation(_, let newAnchor) = rows[5]
        else {
            Issue.record("unexpected row structure")
            return
        }
        #expect(deleted.kind == .deletion)
        #expect(oldAnchor == DiffFileAnchor(path: "Example.swift", anchor: .old(2)))
        #expect(added.kind == .addition)
        #expect(newAnchor == DiffFileAnchor(path: "Example.swift", anchor: .new(2)))
    }

    @Test("context lines answer to the new side first")
    func contextAnchorPriority() {
        let rows = DiffRow.rows(for: file, annotatedAnchors: [.new(1)])

        guard case .annotation(_, let anchor) = rows[2] else {
            Issue.record("annotation row not inserted after context line")
            return
        }
        #expect(anchor.anchor == .new(1))
    }

    @Test("multi-file rows interleave file headers and skip collapsed bodies")
    func multiFileRows() {
        let second = FileDiff(path: "Other.swift", status: .added, hunks: file.hunks)

        let rows = DiffRow.rows(
            for: [file, second],
            collapsedFiles: [second.path],
            viewedFiles: [second.path],
            annotatedAnchors: [:]
        )

        guard case .fileHeader(0, let first, false, false) = rows[0] else {
            Issue.record("expected expanded, unviewed header for the first file")
            return
        }
        #expect(first.path == "Example.swift")

        guard case .fileHeader(_, let collapsed, true, true) = rows[rows.count - 1] else {
            Issue.record("expected collapsed, viewed trailing header")
            return
        }
        #expect(collapsed.path == "Other.swift")
        // header + hunk header + 3 lines + collapsed header
        #expect(rows.count == 6)
    }
}
