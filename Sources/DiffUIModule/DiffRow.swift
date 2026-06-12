import Foundation

/// One renderable row of a file diff, precomputed so lazy containers
/// get stable identity and no per-frame work.
enum DiffRow: Identifiable {
    case hunkHeader(index: Int, header: String)
    /// `counterpart` is the paired opposite-side text used for on-demand
    /// intra-line emphasis; `nil` for unpaired or context lines.
    case line(index: Int, location: LineLocation, line: DiffLine, counterpart: String?)

    var id: Int {
        switch self {
        case .hunkHeader(let index, _): index
        case .line(let index, _, _, _): index
        }
    }

    /// Flattens hunks into rows, attaching pairing information.
    static func rows(for fileDiff: FileDiff) -> [DiffRow] {
        var rows: [DiffRow] = []
        for (hunkIndex, hunk) in fileDiff.hunks.enumerated() {
            rows.append(.hunkHeader(index: rows.count, header: hunk.header))
            let counterparts = hunk.intralineCounterparts
            for (lineIndex, line) in hunk.lines.enumerated() {
                rows.append(.line(
                    index: rows.count,
                    location: LineLocation(hunk: hunkIndex, line: lineIndex),
                    line: line,
                    counterpart: counterparts[lineIndex]
                ))
            }
        }
        return rows
    }
}
