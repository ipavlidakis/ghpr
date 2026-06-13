import Foundation
import Testing
@testable import ghpr

/// Checks digest stability and sensitivity to content changes.
@Suite("FileDiff digest")
struct FileDiffDigestTests {
    private func file(text: String) -> FileDiff {
        FileDiff(
            path: "Example.swift",
            status: .modified,
            hunks: [
                DiffHunk(header: "@@ -1 +1 @@", oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, lines: [
                    DiffLine(kind: .addition, text: text, oldLineNumber: nil, newLineNumber: 1)
                ])
            ]
        )
    }

    @Test("identical content produces identical digests")
    func deterministic() {
        #expect(file(text: "let a = 1").contentDigest == file(text: "let a = 1").contentDigest)
    }

    @Test("changed content produces a different digest")
    func sensitive() {
        #expect(file(text: "let a = 1").contentDigest != file(text: "let a = 2").contentDigest)
    }
}
