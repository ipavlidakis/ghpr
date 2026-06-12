/// One renderable row of a file diff, precomputed so lazy containers
/// get stable identity and no per-frame work.
enum DiffRow: Identifiable {
    case hunkHeader(index: Int, header: String)
    case line(index: Int, line: DiffLine, emphasis: [Range<String.Index>]?)

    var id: Int {
        switch self {
        case .hunkHeader(let index, _), .line(let index, _, _): index
        }
    }
}

extension DiffRow {
    /// Flattens hunks into rows, attaching intra-line emphasis.
    static func rows(for fileDiff: FileDiff) -> [DiffRow] {
        var rows: [DiffRow] = []
        for hunk in fileDiff.hunks {
            rows.append(.hunkHeader(index: rows.count, header: hunk.header))
            let emphasis = hunk.intralineEmphasis
            for (lineIndex, line) in hunk.lines.enumerated() {
                rows.append(.line(index: rows.count, line: line, emphasis: emphasis[lineIndex]))
            }
        }
        return rows
    }
}
