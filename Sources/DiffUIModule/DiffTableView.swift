import AppKit
import Foundation
import SwiftUI

/// The diff row host: a fixed-row-height `NSTableView`.
///
/// SwiftUI's `List` builds and measures hosting views for rows en masse —
/// an Instruments trace showed multi-hundred-millisecond main-thread hitches
/// in AttributeGraph allocation and observer teardown when opening and
/// scrolling large files. A plain `NSTableView` with `usesAutomaticRowHeights`
/// off does no offscreen work at all: any file opens instantly and scrolling
/// only ever materializes visible rows.
struct DiffTableView: NSViewRepresentable {
    let rows: [DiffRow]
    let gutterDigits: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: rows, gutterDigits: gutterDigits)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tableView = NSTableView()
        tableView.addTableColumn(NSTableColumn(identifier: Coordinator.columnIdentifier))
        tableView.headerView = nil
        tableView.rowHeight = DiffStyle.rowHeight
        tableView.usesAutomaticRowHeights = false
        tableView.intercellSpacing = .zero
        tableView.selectionHighlightStyle = .none
        tableView.style = .plain
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.update(rows: rows, gutterDigits: gutterDigits)
        (scrollView.documentView as? NSTableView)?.reloadData()
    }

    /// Data source and delegate vending recycled, fixed-height cells.
    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        static let columnIdentifier = NSUserInterfaceItemIdentifier("diffLine")
        private static let cellIdentifier = NSUserInterfaceItemIdentifier("diffLineCell")

        private var rows: [DiffRow]
        private var gutterDigits: Int

        init(rows: [DiffRow], gutterDigits: Int) {
            self.rows = rows
            self.gutterDigits = gutterDigits
        }

        func update(rows: [DiffRow], gutterDigits: Int) {
            self.rows = rows
            self.gutterDigits = gutterDigits
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            rows.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row index: Int) -> NSView? {
            let cell: DiffLineCellView
            if let recycled = tableView.makeView(withIdentifier: Self.cellIdentifier, owner: nil) as? DiffLineCellView {
                cell = recycled
            } else {
                cell = DiffLineCellView()
                cell.identifier = Self.cellIdentifier
            }
            cell.configure(with: rows[index], gutterDigits: gutterDigits)
            return cell
        }

        func tableView(_ tableView: NSTableView, rowViewForRow index: Int) -> NSTableRowView? {
            let rowView = NSTableRowView()
            switch rows[index] {
            case .hunkHeader:
                rowView.backgroundColor = DiffStyle.hunkHeaderBackground
            case .line(_, let line, _):
                switch line.kind {
                case .context: rowView.backgroundColor = .clear
                case .addition: rowView.backgroundColor = DiffStyle.additionBackground
                case .deletion: rowView.backgroundColor = DiffStyle.deletionBackground
                }
            }
            return rowView
        }
    }
}
