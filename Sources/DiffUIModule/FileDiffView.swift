import Foundation
import SwiftUI

/// Renders one file's diff: collapsible header plus the fixed-row-height
/// table of hunk headers and code lines (gutter numbers, add/delete tinting,
/// on-demand intra-line word emphasis, background syntax highlighting).
///
/// Owns its own scrolling — do not wrap it in a `ScrollView`.
///
/// `annotations` pins arbitrary caller views (review threads — this module
/// never knows what they are) under the lines they anchor to.
package struct FileDiffView: View {
    private let fileDiff: FileDiff
    private let highlighter: SyntaxHighlighter
    private let annotations: [DiffLineAnchor: AnyView]
    private let rows: [DiffRow]
    private let gutterDigits: Int

    @State private var isCollapsed = false
    @State private var highlights: FileSyntaxHighlights?

    package init(
        fileDiff: FileDiff,
        highlighter: SyntaxHighlighter,
        annotations: [DiffLineAnchor: AnyView] = [:]
    ) {
        self.fileDiff = fileDiff
        self.highlighter = highlighter
        self.annotations = annotations
        rows = DiffRow.rows(for: fileDiff, annotatedAnchors: Set(annotations.keys))
        gutterDigits = DiffStyle.gutterDigits(for: fileDiff)
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FileDiffHeaderView(fileDiff: fileDiff, isCollapsed: $isCollapsed)
            if !isCollapsed {
                content
            }
        }
        .background(.background)
        .clipShape(.rect(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator, lineWidth: 1)
        )
        .task(id: fileDiff.path) {
            highlights = await highlighter.highlights(for: fileDiff)
        }
    }

    @ViewBuilder
    private var content: some View {
        if fileDiff.isBinary {
            Text("Binary file not shown")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(8)
        } else {
            DiffTableView(rows: rows, gutterDigits: gutterDigits, highlights: highlights, annotations: annotations)
        }
    }
}
