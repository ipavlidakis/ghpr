import Foundation
import SwiftUI

/// Continuous, GitHub-style scroll through every changed file: file header
/// rows (click to collapse) followed by each file's diff. Reports the file
/// at the top of the viewport so a sidebar can follow, and scrolls to a
/// file on request.
package struct MultiFileDiffView: View {
    private let files: [FileDiff]
    private let highlighter: SyntaxHighlighter
    private let annotations: [DiffFileAnchor: DiffAnnotation]
    private let filePreviews: [String: DiffAnnotation]
    private let viewedFiles: Set<String>
    private let collapsedFiles: Set<String>
    private let onViewedToggle: ((String, Bool) -> Void)?
    private let onCollapseToggle: ((String) -> Void)?
    private let onLineClick: ((String, DiffLine) -> Void)?
    private let onExpandFile: ((String) -> Void)?
    private let expandedFiles: Set<String>
    private let fileActions: [DiffFileAction]
    private let onVisibleFileChange: ((String) -> Void)?
    private let scrollTarget: DiffScrollTarget?
    private let gutterDigits: Int

    @State private var highlightsByFile: [String: FileSyntaxHighlights] = [:]

    package init(
        files: [FileDiff],
        highlighter: SyntaxHighlighter,
        annotations: [DiffFileAnchor: DiffAnnotation] = [:],
        filePreviews: [String: DiffAnnotation] = [:],
        viewedFiles: Set<String> = [],
        collapsedFiles: Set<String> = [],
        onViewedToggle: ((String, Bool) -> Void)? = nil,
        onCollapseToggle: ((String) -> Void)? = nil,
        onLineClick: ((String, DiffLine) -> Void)? = nil,
        onExpandFile: ((String) -> Void)? = nil,
        expandedFiles: Set<String> = [],
        fileActions: [DiffFileAction] = [],
        onVisibleFileChange: ((String) -> Void)? = nil,
        scrollTarget: DiffScrollTarget? = nil
    ) {
        self.files = files
        self.highlighter = highlighter
        self.annotations = annotations
        self.filePreviews = filePreviews
        self.viewedFiles = viewedFiles
        self.collapsedFiles = collapsedFiles
        self.onViewedToggle = onViewedToggle
        self.onCollapseToggle = onCollapseToggle
        self.onLineClick = onLineClick
        self.onExpandFile = onExpandFile
        self.expandedFiles = expandedFiles
        self.fileActions = fileActions
        self.onVisibleFileChange = onVisibleFileChange
        self.scrollTarget = scrollTarget
        gutterDigits = files.map(DiffStyle.gutterDigits(for:)).max() ?? 3
    }

    package var body: some View {
        DiffTableView(
            rows: DiffRow.rows(
                for: files,
                collapsedFiles: collapsedFiles,
                viewedFiles: viewedFiles,
                annotatedAnchors: annotatedAnchors,
                previewPaths: Set(filePreviews.keys)
            ),
            gutterDigits: gutterDigits,
            highlightsByFile: highlightsByFile,
            annotations: annotations,
            filePreviews: filePreviews,
            onLineClick: onLineClick,
            onFileHeaderClick: { path in
                onCollapseToggle?(path)
            },
            onViewedToggle: { path, isViewed in
                onViewedToggle?(path, isViewed)
            },
            onExpandFile: onExpandFile,
            expandedFiles: expandedFiles,
            fileActions: fileActions,
            onVisibleFileChange: onVisibleFileChange,
            scrollTarget: scrollTarget
        )
        .task(id: files.map(\.path)) {
            for file in files {
                if Task.isCancelled { return }
                if highlightsByFile[file.path] == nil, let highlights = await highlighter.highlights(for: file) {
                    highlightsByFile[file.path] = highlights
                }
            }
        }
    }

    private var annotatedAnchors: [String: Set<DiffLineAnchor>] {
        var anchors: [String: Set<DiffLineAnchor>] = [:]
        for key in annotations.keys {
            anchors[key.path, default: []].insert(key.anchor)
        }
        return anchors
    }
}
