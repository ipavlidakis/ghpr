import Testing
import DiffUIModule

@Suite("DiffHunk intraline emphasis")
struct DiffHunkIntralineEmphasisTests {
    private func hunk(_ lines: [DiffLine]) -> DiffHunk {
        DiffHunk(header: "@@ -1 +1 @@", oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, lines: lines)
    }

    @Test("paired deletion/addition runs get emphasis at matching offsets")
    func pairedRuns() {
        let hunk = hunk([
            DiffLine(kind: .context, text: "unchanged", oldLineNumber: 1, newLineNumber: 1),
            DiffLine(kind: .deletion, text: "let a = 1", oldLineNumber: 2, newLineNumber: nil),
            DiffLine(kind: .deletion, text: "let b = 2", oldLineNumber: 3, newLineNumber: nil),
            DiffLine(kind: .addition, text: "let a = 10", oldLineNumber: nil, newLineNumber: 2),
            DiffLine(kind: .addition, text: "let b = 20", oldLineNumber: nil, newLineNumber: 3),
        ])

        let emphasis = hunk.intralineEmphasis

        // Lines 1↔3 and 2↔4 are pairs; the context line has no emphasis.
        #expect(emphasis.keys.sorted() == [1, 2, 3, 4])
        #expect(emphasis[1]?.map { String(hunk.lines[1].text[$0]) } == ["1"])
        #expect(emphasis[3]?.map { String(hunk.lines[3].text[$0]) } == ["10"])
    }

    @Test("an unpaired deletion gets no emphasis")
    func unpairedDeletion() {
        let hunk = hunk([
            DiffLine(kind: .deletion, text: "gone forever", oldLineNumber: 1, newLineNumber: nil),
            DiffLine(kind: .context, text: "unchanged", oldLineNumber: 2, newLineNumber: 1),
        ])

        #expect(hunk.intralineEmphasis.isEmpty)
    }

    @Test("extra additions beyond the paired count get no emphasis")
    func extraAdditions() {
        let hunk = hunk([
            DiffLine(kind: .deletion, text: "let a = 1", oldLineNumber: 1, newLineNumber: nil),
            DiffLine(kind: .addition, text: "let a = 10", oldLineNumber: nil, newLineNumber: 1),
            DiffLine(kind: .addition, text: "let entirelyNew = true", oldLineNumber: nil, newLineNumber: 2),
        ])

        let emphasis = hunk.intralineEmphasis

        #expect(emphasis.keys.sorted() == [0, 1])
    }
}
