import Foundation
import Testing
import DiffUIModule

/// Verifies deletion/addition run pairing within a hunk.
@Suite("DiffHunk intraline counterparts")
struct DiffHunkIntralineCounterpartsTests {
    private func hunk(_ lines: [DiffLine]) -> DiffHunk {
        DiffHunk(header: "@@ -1 +1 @@", oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, lines: lines)
    }

    @Test("paired deletion/addition runs reference each other's text")
    func pairedRuns() {
        let hunk = hunk([
            DiffLine(kind: .context, text: "unchanged", oldLineNumber: 1, newLineNumber: 1),
            DiffLine(kind: .deletion, text: "let a = 1", oldLineNumber: 2, newLineNumber: nil),
            DiffLine(kind: .deletion, text: "let b = 2", oldLineNumber: 3, newLineNumber: nil),
            DiffLine(kind: .addition, text: "let a = 10", oldLineNumber: nil, newLineNumber: 2),
            DiffLine(kind: .addition, text: "let b = 20", oldLineNumber: nil, newLineNumber: 3),
        ])

        let counterparts = hunk.intralineCounterparts

        #expect(counterparts.keys.sorted() == [1, 2, 3, 4])
        #expect(counterparts[1] == "let a = 10")
        #expect(counterparts[2] == "let b = 20")
        #expect(counterparts[3] == "let a = 1")
        #expect(counterparts[4] == "let b = 2")
    }

    @Test("an unpaired deletion gets no counterpart")
    func unpairedDeletion() {
        let hunk = hunk([
            DiffLine(kind: .deletion, text: "gone forever", oldLineNumber: 1, newLineNumber: nil),
            DiffLine(kind: .context, text: "unchanged", oldLineNumber: 2, newLineNumber: 1),
        ])

        #expect(hunk.intralineCounterparts.isEmpty)
    }

    @Test("extra additions beyond the paired count get no counterpart")
    func extraAdditions() {
        let hunk = hunk([
            DiffLine(kind: .deletion, text: "let a = 1", oldLineNumber: 1, newLineNumber: nil),
            DiffLine(kind: .addition, text: "let a = 10", oldLineNumber: nil, newLineNumber: 1),
            DiffLine(kind: .addition, text: "let entirelyNew = true", oldLineNumber: nil, newLineNumber: 2),
        ])

        let counterparts = hunk.intralineCounterparts

        #expect(counterparts.keys.sorted() == [0, 1])
        #expect(counterparts[0] == "let a = 10")
        #expect(counterparts[1] == "let a = 1")
    }
}
