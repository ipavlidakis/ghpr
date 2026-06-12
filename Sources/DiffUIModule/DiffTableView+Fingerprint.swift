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
        // Content versions matter: a collapsed thread changes the view and
        // its height without changing the anchor set.
        hasher.combine(annotations.map { "\($0.key.path)|\($0.key.anchor)|\($0.value.version)" }.sorted())
        hasher.combine(filePreviews.map { "\($0.key)|\($0.value.version)" }.sorted())
        return hasher.finalize()
    }
}
