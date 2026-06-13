import Foundation
import SwiftUI

/// Continuous, GitHub-style scroll through every changed file: file header
/// rows (click to collapse) followed by each file's diff. Reports the file
/// at the top of the viewport so a sidebar can follow, and scrolls to a
/// file on request.
package struct MultiFileDiffView: View, Equatable {
    private let files: [FileDiff]
    private let highlighter: SyntaxHighlighter
    private let annotations: [DiffFileAnchor: DiffAnnotation]
    private let filePreviews: [String: DiffAnnotation]
    private let fileSignature: [FileSignature]
    private let annotationSignature: [String]
    private let filePreviewSignature: [String]
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
    @State private var loadedLargeDiffs: Set<String> = []

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
        fileSignature = files.map { FileSignature(file: $0) }
        annotationSignature = Self.signature(for: annotations)
        filePreviewSignature = Self.signature(for: filePreviews)
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
        let guardedPaths = guardedLargeDiffs
        let previews = effectiveFilePreviews(guardedPaths: guardedPaths)
        DiffTableView(
            rows: DiffRow.rows(
                for: files,
                collapsedFiles: collapsedFiles,
                viewedFiles: viewedFiles,
                annotatedAnchors: annotatedAnchors,
                previewPaths: Set(previews.keys)
            ),
            gutterDigits: gutterDigits,
            highlightsByFile: highlightsByFile,
            annotations: annotations,
            filePreviews: previews,
            onLineClick: onLineClick,
            onFileHeaderClick: { path in
                onCollapseToggle?(path)
            },
            onViewedToggle: { path, isViewed in
                onViewedToggle?(path, isViewed)
            },
            onLoadPreview: { path in
                loadedLargeDiffs.insert(path)
            },
            onExpandFile: onExpandFile,
            expandedFiles: expandedFiles,
            fileActions: fileActions,
            onVisibleFileChange: onVisibleFileChange,
            scrollTarget: scrollTarget
        )
        .task(id: guardedPaths) {
            for file in files {
                if Task.isCancelled { return }
                guard !guardedPaths.contains(file.path) else { continue }
                if highlightsByFile[file.path] == nil, let highlights = await highlighter.highlights(for: file) {
                    highlightsByFile[file.path] = highlights
                }
            }
        }
    }

    nonisolated package static func == (lhs: MultiFileDiffView, rhs: MultiFileDiffView) -> Bool {
        lhs.filesSignature == rhs.filesSignature
            && lhs.annotationSignature == rhs.annotationSignature
            && lhs.filePreviewSignature == rhs.filePreviewSignature
            && lhs.viewedFiles == rhs.viewedFiles
            && lhs.collapsedFiles == rhs.collapsedFiles
            && lhs.expandedFiles == rhs.expandedFiles
            && lhs.fileActions.map(\.title) == rhs.fileActions.map(\.title)
            && lhs.scrollTarget == rhs.scrollTarget
    }

    nonisolated private var filesSignature: [FileSignature] {
        fileSignature
    }

    private static func signature(for annotations: [DiffFileAnchor: DiffAnnotation]) -> [String] {
        annotations.map { "\($0.key.path)|\($0.key.anchor)|\($0.value.version)" }.sorted()
    }

    private static func signature(for previews: [String: DiffAnnotation]) -> [String] {
        previews.map { "\($0.key)|\($0.value.version)" }.sorted()
    }

    private func effectiveFilePreviews(guardedPaths: Set<String>) -> [String: DiffAnnotation] {
        var previews = filePreviews
        for file in files where guardedPaths.contains(file.path) {
            previews[file.path] = DiffAnnotation(
                version: file.additions + file.deletions,
                fixedHeight: 136,
                content: AnyView(EmptyView())
            )
        }
        return previews
    }

    private var guardedLargeDiffs: Set<String> {
        Set(files.filter(shouldGuard).map(\.path)).subtracting(loadedLargeDiffs)
    }

    private func shouldGuard(_ file: FileDiff) -> Bool {
        guard !file.isBinary else { return false }
        let changedLines = file.additions + file.deletions
        return changedLines >= 300 || file.renderedLines >= 600
    }

    private var annotatedAnchors: [String: Set<DiffLineAnchor>] {
        var anchors: [String: Set<DiffLineAnchor>] = [:]
        for key in annotations.keys {
            anchors[key.path, default: []].insert(key.anchor)
        }
        return anchors
    }
}

private struct FileSignature: Equatable {
    let path: String
    let status: FileDiffStatus
    let additions: Int
    let deletions: Int
    let renderedLines: Int
    let hunkHeaders: [String]

    init(file: FileDiff) {
        path = file.path
        status = file.status
        additions = file.additions
        deletions = file.deletions
        renderedLines = file.renderedLines
        hunkHeaders = file.hunks.map(\.header)
    }
}
