import Foundation
import Testing
import DiffUIModule

/// Covers tokenization, range merging, and the similarity heuristic.
@Suite("IntralineDiff")
struct IntralineDiffTests {
    @Test("a single changed word is emphasized on both sides")
    func singleWordChange() {
        let old = "let x = compute(a, b)"
        let new = "let y = compute(a, b)"

        let (oldRanges, newRanges) = IntralineDiff.changedRanges(old: old, new: new)

        #expect(oldRanges.map { String(old[$0]) } == ["x"])
        #expect(newRanges.map { String(new[$0]) } == ["y"])
    }

    @Test("identical lines produce no emphasis")
    func identical() {
        let (oldRanges, newRanges) = IntralineDiff.changedRanges(old: "same", new: "same")

        #expect(oldRanges.isEmpty)
        #expect(newRanges.isEmpty)
    }

    @Test("mostly different lines skip emphasis entirely")
    func dissimilar() {
        let (oldRanges, newRanges) = IntralineDiff.changedRanges(
            old: "private func legacyImplementation()",
            new: "var answer = 42"
        )

        #expect(oldRanges.isEmpty)
        #expect(newRanges.isEmpty)
    }

    @Test("adjacent changed tokens merge into one range")
    func mergedRanges() {
        let old = "value.method()"
        let new = "value.newName()"

        let (oldRanges, newRanges) = IntralineDiff.changedRanges(old: old, new: new)

        #expect(oldRanges.map { String(old[$0]) } == ["method"])
        #expect(newRanges.map { String(new[$0]) } == ["newName"])
    }

    @Test("an appended argument emphasizes only the new tokens")
    func appendedTokens() {
        let old = "fetch(url)"
        let new = "fetch(url, retries: 3)"

        let (oldRanges, newRanges) = IntralineDiff.changedRanges(old: old, new: new)

        #expect(oldRanges.isEmpty)
        #expect(newRanges.map { String(new[$0]) } == [", retries: 3"])
    }
}
