extension DiffHunk {
    /// Intra-line changed ranges, keyed by index into `lines`.
    ///
    /// Pairs each run of deletions with the run of additions that follows it
    /// (k-th deletion with k-th addition), the way reviewers read a hunk.
    package var intralineEmphasis: [Int: [Range<String.Index>]] {
        var result: [Int: [Range<String.Index>]] = [:]
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
                let deletionIndex = deletionsStart + offset
                let additionIndex = additionsStart + offset
                let ranges = IntralineDiff.changedRanges(
                    old: lines[deletionIndex].text,
                    new: lines[additionIndex].text
                )
                if !ranges.old.isEmpty { result[deletionIndex] = ranges.old }
                if !ranges.new.isEmpty { result[additionIndex] = ranges.new }
            }
        }
        return result
    }
}
