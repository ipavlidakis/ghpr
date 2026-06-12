import Foundation

/// Deletion/addition run pairing for intra-line emphasis.
extension DiffHunk {
    /// The opposite side's text for every paired changed line, keyed by index
    /// into `lines`: the k-th deletion of a run pairs with the k-th addition
    /// that follows it, the way reviewers read a hunk.
    ///
    /// Only the pairing happens here — the word-level diff itself runs lazily
    /// per visible row, so opening a huge file stays instant.
    package var intralineCounterparts: [Int: String] {
        var result: [Int: String] = [:]
        var index = 0
        while index < lines.count {
            guard lines[index].kind == .deletion else {
                index += 1
                continue
            }

            let deletionsStart = index
            while index < lines.count, lines[index].kind == .deletion { index += 1 }
            let additionsStart = index
            while index < lines.count, lines[index].kind == .addition { index += 1 }

            let pairCount = min(additionsStart - deletionsStart, index - additionsStart)
            for offset in 0..<pairCount {
                result[deletionsStart + offset] = lines[additionsStart + offset].text
                result[additionsStart + offset] = lines[deletionsStart + offset].text
            }
        }
        return result
    }
}
