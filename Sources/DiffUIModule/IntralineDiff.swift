/// Word-level difference between a paired deleted and added line,
/// computed with Myers diff (`CollectionDifference`) over tokens.
package enum IntralineDiff {
    /// Character ranges that changed on each side.
    ///
    /// Returns empty ranges when the lines are mostly different — emphasizing
    /// nearly everything reads worse than plain add/delete tinting.
    package static func changedRanges(
        old: String,
        new: String
    ) -> (old: [Range<String.Index>], new: [Range<String.Index>]) {
        let oldTokens = tokens(old)
        let newTokens = tokens(new)
        let difference = newTokens.difference(from: oldTokens)

        var oldRanges: [Range<String.Index>] = []
        var newRanges: [Range<String.Index>] = []
        for change in difference {
            switch change {
            case .remove(let offset, _, _):
                oldRanges.append(oldTokens[offset].startIndex..<oldTokens[offset].endIndex)
            case .insert(let offset, _, _):
                newRanges.append(newTokens[offset].startIndex..<newTokens[offset].endIndex)
            }
        }
        oldRanges = merged(oldRanges)
        newRanges = merged(newRanges)

        guard isMostlyUnchanged(old, oldRanges) || isMostlyUnchanged(new, newRanges) else {
            return ([], [])
        }
        return (oldRanges, newRanges)
    }

    /// Splits into word tokens (letters, digits, `_`) and single non-word characters.
    private static func tokens(_ text: String) -> [Substring] {
        var result: [Substring] = []
        var current = text.startIndex
        while current < text.endIndex {
            var end = text.index(after: current)
            if isWord(text[current]) {
                while end < text.endIndex, isWord(text[end]) {
                    end = text.index(after: end)
                }
            }
            result.append(text[current..<end])
            current = end
        }
        return result
    }

    private static func isWord(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_"
    }

    private static func merged(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }
        var result: [Range<String.Index>] = []
        for range in sorted {
            if let last = result.last, last.upperBound >= range.lowerBound {
                result[result.count - 1] = last.lowerBound..<max(last.upperBound, range.upperBound)
            } else {
                result.append(range)
            }
        }
        return result
    }

    private static func isMostlyUnchanged(_ text: String, _ changed: [Range<String.Index>]) -> Bool {
        guard !text.isEmpty else { return false }
        let changedCount = changed.reduce(0) { $0 + text.distance(from: $1.lowerBound, to: $1.upperBound) }
        return Double(changedCount) / Double(text.count) <= 0.7
    }
}
