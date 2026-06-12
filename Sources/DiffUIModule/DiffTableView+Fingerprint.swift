import Foundation

/// Change detection for reloads.
extension DiffTableView {
    /// Cheap change detector: reloads only happen when content really
    /// changed, never when unrelated parent state (sidebar selection
    /// following a scroll) re-evaluates the body.
    var contentFingerprint: Int {
        var hasher = Hasher()
        hasher.combine(rows.count)
        hasher.combine(gutterDigits)
        for row in rows {
            if case .fileHeader(_, let file, let isCollapsed, let isViewed) = row {
                hasher.combine(file.path)
                hasher.combine(isCollapsed)
                hasher.combine(isViewed)
            }
        }
        hasher.combine(highlightsByFile.keys.sorted())
        hasher.combine(expandedFiles.sorted())
        hasher.combine(annotations.keys.map { "\($0.path)|\($0.anchor)" }.sorted())
        return hasher.finalize()
    }
}
