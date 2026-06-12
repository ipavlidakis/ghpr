import Foundation

/// One renderable row of a file diff, precomputed so lazy containers
/// get stable identity and no per-frame work.
enum DiffRow: Identifiable {
    case hunkHeader(index: Int, header: String)
    /// `counterpart` is the paired opposite-side text used for on-demand
    /// intra-line emphasis; `nil` for unpaired or context lines.
    case line(index: Int, location: LineLocation, line: DiffLine, counterpart: String?)
    /// Caller-provided content (review threads) pinned under a line.
    case annotation(index: Int, anchor: DiffLineAnchor)

    var id: Int {
        switch self {
        case .hunkHeader(let index, _): index
        case .line(let index, _, _, _): index
        case .annotation(let index, _): index
        }
    }

    /// Flattens hunks into rows, attaching pairing information and inserting
    /// an annotation row after each line that has anchored content.
    static func rows(for fileDiff: FileDiff, annotatedAnchors: Set<DiffLineAnchor> = []) -> [DiffRow] {
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
                if let anchor = line.anchors.first(where: annotatedAnchors.contains) {
                    rows.append(.annotation(index: rows.count, anchor: anchor))
                }
            }
        }
        return rows
    }
}
