import AppKit
import Foundation

@MainActor
final class FileListOutlineCoordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    static let columnIdentifier = NSUserInterfaceItemIdentifier("file")
    private static let cellIdentifier = NSUserInterfaceItemIdentifier("fileListCell")

    private var tree: [FileTreeNode] = []
    private var selectedPath: String?
    private var onSelect: ((FileListItem) -> Void)?
    private var treeFingerprint = ""
    private var isApplyingSelection = false

    func apply(_ view: FileListOutlineView, to outlineView: NSOutlineView) {
        tree = view.tree
        selectedPath = view.selectedPath
        onSelect = view.onSelect

        let fingerprint = fingerprint(for: view.tree)
        if fingerprint != treeFingerprint {
            treeFingerprint = fingerprint
            outlineView.reloadData()
            outlineView.expandItem(nil, expandChildren: true)
        }

        select(view.selectedPath, in: outlineView)
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        children(of: item).count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        children(of: item)[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        node(from: item)?.children?.isEmpty == false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        node(from: item)?.item != nil
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = node(from: item) else { return nil }
        let cell: FileListCellView
        if let recycled = outlineView.makeView(withIdentifier: Self.cellIdentifier, owner: nil) as? FileListCellView {
            cell = recycled
        } else {
            cell = FileListCellView()
            cell.identifier = Self.cellIdentifier
        }
        cell.configure(with: node)
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard
            !isApplyingSelection,
            let outlineView = notification.object as? NSOutlineView
        else { return }

        let row = outlineView.selectedRow
        guard
            row >= 0,
            let node = outlineView.item(atRow: row) as? FileTreeNode,
            let item = node.item
        else { return }

        onSelect?(item)
    }

    private func children(of item: Any?) -> [FileTreeNode] {
        if let item, let node = node(from: item) {
            return node.children ?? []
        }
        return tree
    }

    private func node(from item: Any) -> FileTreeNode? {
        item as? FileTreeNode
    }

    private func select(_ path: String?, in outlineView: NSOutlineView) {
        isApplyingSelection = true
        defer { isApplyingSelection = false }

        guard let path else {
            outlineView.deselectAll(nil)
            return
        }

        for row in 0..<outlineView.numberOfRows {
            guard
                let node = outlineView.item(atRow: row) as? FileTreeNode,
                node.item?.path == path
            else { continue }

            if outlineView.selectedRow != row {
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
            outlineView.scrollRowToVisible(row)
            return
        }
    }

    private func fingerprint(for nodes: [FileTreeNode]) -> String {
        var parts: [String] = []
        func walk(_ nodes: [FileTreeNode]) {
            for node in nodes {
                parts.append(node.id)
                if let children = node.children {
                    walk(children)
                }
            }
        }
        walk(nodes)
        return parts.joined(separator: "\n")
    }
}
