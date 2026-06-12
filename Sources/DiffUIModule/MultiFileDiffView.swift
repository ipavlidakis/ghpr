import Foundation
import SwiftUI

/// Continuous, GitHub-style scroll through every changed file: file header
/// rows (click to collapse) followed by each file's diff. Reports the file
/// at the top of the viewport so a sidebar can follow, and scrolls to a
/// file on request.
package struct MultiFileDiffView: View {
    private let files: [FileDiff]
    private let highlighter: SyntaxHighlighter
    private let annotations: [DiffFileAnchor: AnyView]
    private let onLineClick: ((String, DiffLine) -> Void)?
    private let onVisibleFileChange: ((String) -> Void)?
    private let scrollTarget: DiffScrollTarget?
    private let gutterDigits: Int

    @State private var collapsedFiles: Set<String> = []
    @State private var highlightsByFile: [String: FileSyntaxHighlights] = [:]

    package init(
        files: [FileDiff],
        highlighter: SyntaxHighlighter,
        annotations: [DiffFileAnchor: AnyView] = [:],
        onLineClick: ((String, DiffLine) -> Void)? = nil,
        onVisibleFileChange: ((String) -> Void)? = nil,
        scrollTarget: DiffScrollTarget? = nil
    ) {
        self.files = files
        self.highlighter = highlighter
        self.annotations = annotations
        self.onLineClick = onLineClick
        self.onVisibleFileChange = onVisibleFileChange
        self.scrollTarget = scrollTarget
        gutterDigits = files.map(DiffStyle.gutterDigits(for:)).max() ?? 3
    }

    package var body: some View {
        DiffTableView(
            rows: DiffRow.rows(
                for: files,
                collapsedFiles: collapsedFiles,
                annotatedAnchors: annotatedAnchors
            ),
            gutterDigits: gutterDigits,
            highlightsByFile: highlightsByFile,
            annotations: annotations,
            onLineClick: onLineClick,
            onFileHeaderClick: { path in
                if !collapsedFiles.insert(path).inserted {
                    collapsedFiles.remove(path)
                }
            },
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
