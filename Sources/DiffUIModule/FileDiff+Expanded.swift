import Foundation

/// Full-context expansion: rebuilds the diff against the complete new-side
/// file so every unchanged line is visible.
extension FileDiff {
    package func expanded(withNewFileContent content: String) -> FileDiff {
        var newContentLines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if newContentLines.last?.isEmpty == true {
            newContentLines.removeLast()
        }

        // Index the changes: additions by new line number, deletions by the
        // new line number they follow.
        var additions: [Int: DiffLine] = [:]
        var deletionsAfter: [Int: [DiffLine]] = [:]
        for hunk in hunks {
            var lastNewLine = hunk.newStart - 1
            for line in hunk.lines {
                switch line.kind {
                case .addition:
                    if let newNumber = line.newLineNumber {
                        additions[newNumber] = line
                        lastNewLine = newNumber
                    }
                case .deletion:
                    deletionsAfter[lastNewLine, default: []].append(line)
                case .context:
                    lastNewLine = line.newLineNumber ?? lastNewLine
                }
            }
        }

        var lines: [DiffLine] = []
        var oldNumber = 1
        for deletion in deletionsAfter[0] ?? [] {
            lines.append(deletion)
            oldNumber = (deletion.oldLineNumber ?? oldNumber) + 1
        }
        for (index, text) in newContentLines.enumerated() {
            let newNumber = index + 1
            if let addition = additions[newNumber] {
                lines.append(addition)
            } else {
                lines.append(DiffLine(kind: .context, text: text, oldLineNumber: oldNumber, newLineNumber: newNumber))
                oldNumber += 1
            }
            for deletion in deletionsAfter[newNumber] ?? [] {
                lines.append(deletion)
                oldNumber = (deletion.oldLineNumber ?? oldNumber) + 1
            }
        }

        let oldTotal = lines.count(where: { $0.kind != .addition })
        let hunk = DiffHunk(
            header: "@@ -1,\(oldTotal) +1,\(newContentLines.count) @@",
            oldStart: 1,
            oldCount: oldTotal,
            newStart: 1,
            newCount: newContentLines.count,
            lines: lines
        )
        return FileDiff(path: path, status: status, hunks: [hunk], isBinary: isBinary)
    }
}
