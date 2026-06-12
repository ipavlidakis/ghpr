import Foundation
import SwiftUI

/// Renders one file's diff: hunk headers, gutter line numbers, add/delete
/// tinting, intra-line word emphasis, per-file collapse, and a per-line
/// annotation slot the caller fills with arbitrary views (review threads,
/// comment composers — this module never knows).
package struct FileDiffView<Annotation: View>: View {
    private let fileDiff: FileDiff
    private let annotation: (DiffLine) -> Annotation?
    private let rows: [DiffRow]
    private let gutterWidth: CGFloat

    @State private var isCollapsed = false

    package init(fileDiff: FileDiff, annotation: @escaping (DiffLine) -> Annotation?) {
        self.fileDiff = fileDiff
        self.annotation = annotation
        rows = DiffRow.rows(for: fileDiff)
        gutterWidth = DiffStyle.gutterWidth(for: fileDiff)
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
    }

    @ViewBuilder
    private var content: some View {
        if fileDiff.isBinary {
            Text("Binary file not shown")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(8)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rows) { row in
                    DiffRowView(row: row, gutterWidth: gutterWidth, annotation: annotation)
                }
            }
        }
    }
}