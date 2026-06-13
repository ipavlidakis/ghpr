import AppKit
import Foundation
import SwiftUI

/// AppKit-owned file sidebar for large PRs.
///
/// SwiftUI `List`/`DisclosureGroup` spends hundreds of milliseconds diffing
/// large outline trees when selection follows the diff scroll. `NSOutlineView`
/// keeps the same source-list interaction without rebuilding the row tree.
struct FileListOutlineView: NSViewRepresentable {
    let tree: [FileTreeNode]
    let selectedPath: String?
    let onSelect: (FileListItem) -> Void

    func makeCoordinator() -> FileListOutlineCoordinator {
        FileListOutlineCoordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let outlineView = NSOutlineView()
        outlineView.setAccessibilityElement(true)
        outlineView.setAccessibilityIdentifier("ghpr.files.sidebar.outline")
        outlineView.setAccessibilityLabel("Changed files sidebar")
        outlineView.headerView = nil
        outlineView.style = .sourceList
        outlineView.backgroundColor = .clear
        outlineView.rowHeight = 26
        outlineView.indentationPerLevel = 14
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.dataSource = context.coordinator
        outlineView.delegate = context.coordinator

        let column = NSTableColumn(identifier: FileListOutlineCoordinator.columnIdentifier)
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = outlineView

        context.coordinator.apply(self, to: outlineView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let outlineView = scrollView.documentView as? NSOutlineView else { return }
        context.coordinator.apply(self, to: outlineView)
    }
}
