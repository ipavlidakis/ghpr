import Foundation

/// One renderable row of a diff table, precomputed so the table gets stable
/// identity and no per-frame work.
enum DiffRow: Identifiable {
    case fileHeader(index: Int, file: FileDiff, isCollapsed: Bool, isViewed: Bool)
    case hunkHeader(index: Int, header: String)
    /// `counterpart` is the paired opposite-side text used for on-demand
    /// intra-line emphasis; `nil` for unpaired or context lines.
    case line(index: Int, file: String, location: LineLocation, line: DiffLine, counterpart: String?)
    /// Caller-provided content (review threads) pinned under a line.
    case annotation(index: Int, anchor: DiffFileAnchor)
    /// Caller-provided content replacing a file's body (image comparisons).
    case filePreview(index: Int, file: FileDiff)

    var id: Int {
        switch self {
        case .fileHeader(let index, _, _, _): index
        case .hunkHeader(let index, _): index
        case .line(let index, _, _, _, _): index
        case .annotation(let index, _): index
        case .filePreview(let index, _): index
        }
    }

    /// The path of the file this row belongs to.
    var filePath: String? {
        switch self {
        case .fileHeader(_, let file, _, _): file.path
        case .hunkHeader: nil
        case .line(_, let file, _, _, _): file
        case .annotation(_, let anchor): anchor.path
        case .filePreview(_, let file): file.path
        }
    }

    /// Rows for a single file's body (no file header).
    static func rows(for fileDiff: FileDiff, annotatedAnchors: Set<DiffLineAnchor> = []) -> [DiffRow] {
        var rows: [DiffRow] = []
        appendBody(of: fileDiff, annotatedAnchors: annotatedAnchors, previewPaths: [], to: &rows)
        return rows
    }

    /// Rows for a continuous multi-file table: each file contributes a header
    /// row plus, when not collapsed, its body rows. Files in `previewPaths`
    /// render a single preview row as their body instead of diff lines.
    static func rows(
        for files: [FileDiff],
        collapsedFiles: Set<String>,
        viewedFiles: Set<String>,
        annotatedAnchors: [String: Set<DiffLineAnchor>],
        previewPaths: Set<String> = []
    ) -> [DiffRow] {
        var rows: [DiffRow] = []
        for file in files {
            let isCollapsed = collapsedFiles.contains(file.path)
            rows.append(.fileHeader(
                index: rows.count,
                file: file,
                isCollapsed: isCollapsed,
                isViewed: viewedFiles.contains(file.path)
            ))
            if !isCollapsed {
                appendBody(
                    of: file,
                    annotatedAnchors: annotatedAnchors[file.path] ?? [],
                    previewPaths: previewPaths,
                    to: &rows
                )
            }
        }
        return rows
    }

    private static func appendBody(
        of fileDiff: FileDiff,
        annotatedAnchors: Set<DiffLineAnchor>,
        previewPaths: Set<String>,
        to rows: inout [DiffRow]
    ) {
        if previewPaths.contains(fileDiff.path) {
            rows.append(.filePreview(index: rows.count, file: fileDiff))
            return
        }
        for (hunkIndex, hunk) in fileDiff.hunks.enumerated() {
            rows.append(.hunkHeader(index: rows.count, header: hunk.header))
            let counterparts = hunk.intralineCounterparts
            for (lineIndex, line) in hunk.lines.enumerated() {
                rows.append(.line(
                    index: rows.count,
                    file: fileDiff.path,
                    location: LineLocation(hunk: hunkIndex, line: lineIndex),
                    line: line,
                    counterpart: counterparts[lineIndex]
                ))
                if let anchor = line.anchors.first(where: annotatedAnchors.contains) {
                    rows.append(.annotation(
                        index: rows.count,
                        anchor: DiffFileAnchor(path: fileDiff.path, anchor: anchor)
                    ))
                }
            }
        }
    }
}
