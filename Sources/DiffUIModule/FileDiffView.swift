import Foundation
import SwiftUI

/// Renders one file's diff: collapsible header plus the fixed-row-height
/// table of hunk headers and code lines (gutter numbers, add/delete tinting,
/// on-demand intra-line word emphasis).
///
/// Owns its own scrolling — do not wrap it in a `ScrollView`.
///
/// Inline annotation slots (review threads) return with milestone 5 as
/// dedicated table rows; the SwiftUI-`List`-based slot mechanism was removed
/// with the `NSTableView` row host (see PLAN decision log).
package struct FileDiffView: View {
    private let fileDiff: FileDiff
    private let rows: [DiffRow]
    private let gutterDigits: Int

    @State private var isCollapsed = false

    package init(fileDiff: FileDiff) {
        self.fileDiff = fileDiff
        rows = DiffRow.rows(for: fileDiff)
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
    }

    @ViewBuilder
    private var content: some View {
        if fileDiff.isBinary {
            Text("Binary file not shown")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(8)
        } else {
            DiffTableView(rows: rows, gutterDigits: gutterDigits)
        }
    }
}
