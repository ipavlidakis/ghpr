import Foundation

/// Anchor resolution for annotation placement.
extension DiffLine {
    /// The anchors this line answers to: additions on the new side,
    /// deletions on the old side, context lines on both.
    package var anchors: [DiffLineAnchor] {
        switch kind {
        case .addition:
            newLineNumber.map { [.new($0)] } ?? []
        case .deletion:
            oldLineNumber.map { [.old($0)] } ?? []
        case .context:
            [newLineNumber.map { DiffLineAnchor.new($0) }, oldLineNumber.map { DiffLineAnchor.old($0) }]
                .compactMap(\.self)
        }
    }
}
