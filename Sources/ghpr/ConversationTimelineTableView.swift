import AppKit
import Foundation
import SwiftUI

/// AppKit-backed virtualized container for the conversation timeline.
struct ConversationTimelineTableView: NSViewRepresentable {
    let rows: [ConversationTimelineRow]
    let contentVersion: Int
    let rowAccessibilityLabel: (ConversationTimelineRow) -> String
    let rowContent: (ConversationTimelineRow) -> AnyView

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tableView = NSTableView()
        tableView.setAccessibilityIdentifier("ghpr.conversation.timeline.table")
        tableView.setAccessibilityLabel("Pull request conversation timeline")
        tableView.addTableColumn(NSTableColumn(identifier: Coordinator.columnIdentifier))
        tableView.headerView = nil
        tableView.usesAutomaticRowHeights = true
        tableView.rowHeight = 84
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.selectionHighlightStyle = .none
        tableView.style = .plain
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.backgroundColor = .clear

        let scrollView = NSScrollView()
        scrollView.setAccessibilityIdentifier("ghpr.conversation.timeline.scroll")
        scrollView.setAccessibilityLabel("Pull request conversation timeline scroll area")
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.apply(self, to: scrollView)
    }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        static let columnIdentifier = NSUserInterfaceItemIdentifier("timeline")
        private static let cellIdentifier = NSUserInterfaceItemIdentifier("timelineCell")

        private var rows: [ConversationTimelineRow] = []
        private var rowAccessibilityLabel: ((ConversationTimelineRow) -> String)?
        private var rowContent: ((ConversationTimelineRow) -> AnyView)?
        private var fingerprint = 0
        weak var tableView: NSTableView?

        func apply(_ view: ConversationTimelineTableView, to scrollView: NSScrollView) {
            rowContent = view.rowContent
            rowAccessibilityLabel = view.rowAccessibilityLabel
            let width = scrollView.contentView.bounds.width
            if let column = (scrollView.documentView as? NSTableView)?.tableColumns.first, abs(column.width - width) > 1 {
                column.width = width
                fingerprint = 0
            }
            let newFingerprint = Self.fingerprint(rows: view.rows, version: view.contentVersion)
            guard newFingerprint != fingerprint else { return }
            fingerprint = newFingerprint
            rows = view.rows

            guard let tableView = scrollView.documentView as? NSTableView else { return }
            tableView.reloadData()
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            rows.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row >= 0, row < rows.count, let rowContent else { return nil }
            let currentRow = rows[row]
            let cell: ConversationTimelineCellView
            if let recycled = tableView.makeView(withIdentifier: Self.cellIdentifier, owner: nil) as? ConversationTimelineCellView {
                cell = recycled
            } else {
                cell = ConversationTimelineCellView()
                cell.identifier = Self.cellIdentifier
            }
            cell.configure(
                content: rowContent(currentRow),
                accessibilityLabel: rowAccessibilityLabel?(currentRow) ?? "Timeline row"
            )
            return cell
        }

        private static func fingerprint(rows: [ConversationTimelineRow], version: Int) -> Int {
            var hasher = Hasher()
            hasher.combine(version)
            hasher.combine(rows.map(\.id))
            return hasher.finalize()
        }
    }
}
