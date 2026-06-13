import Foundation
import SwiftUI

/// The changed-files tree with native full-row selection: directories as
/// disclosure groups (single-child chains compressed inline, like GitHub),
/// files as selectable rows. Selection flows out through `onSelect` only;
/// the highlighted row flows back in via `selectedPath`.
package struct FileListView: View {
    private let tree: [FileTreeNode]
    private let selectedPath: String?
    private let onSelect: (FileListItem) -> Void

    package init(items: [FileListItem], selectedPath: String?, onSelect: @escaping (FileListItem) -> Void) {
        self.init(
            items: items,
            tree: FileTreeNode.tree(from: items),
            selectedPath: selectedPath,
            onSelect: onSelect
        )
    }

    package init(
        items: [FileListItem],
        tree: [FileTreeNode],
        selectedPath: String?,
        onSelect: @escaping (FileListItem) -> Void
    ) {
        self.tree = tree
        self.selectedPath = selectedPath
        self.onSelect = onSelect
    }

    package var body: some View {
        FileListOutlineView(tree: tree, selectedPath: selectedPath, onSelect: onSelect)
        .accessibilityIdentifier("ghpr.files.sidebar")
        .accessibilityLabel("Changed files sidebar")
        .accessibilityValue(selectedPath ?? "No file selected")
    }
}
