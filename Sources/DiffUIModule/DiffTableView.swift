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
    let highlights: FileSyntaxHighlights?

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: rows, gutterDigits: gutterDigits, highlights: highlights)
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
        context.coordinator.update(rows: rows, gutterDigits: gutterDigits, highlights: highlights)
        (scrollView.documentView as? NSTableView)?.reloadData()
    }

    /// Data source and delegate vending recycled, fixed-height cells.
    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        static let columnIdentifier = NSUserInterfaceItemIdentifier("diffLine")
        private static let cellIdentifier = NSUserInterfaceItemIdentifier("diffLineCell")
        private static let rowIdentifier = NSUserInterfaceItemIdentifier("diffRow")

        private var rows: [DiffRow]
        private var gutterDigits: Int
        private var highlights: FileSyntaxHighlights?

        init(rows: [DiffRow], gutterDigits: Int, highlights: FileSyntaxHighlights?) {
            self.rows = rows
            self.gutterDigits = gutterDigits
            self.highlights = highlights
        }

        func update(rows: [DiffRow], gutterDigits: Int, highlights: FileSyntaxHighlights?) {
            self.rows = rows
            self.gutterDigits = gutterDigits
            self.highlights = highlights
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
            let row = rows[index]
            let tokens: [SyntaxToken] =
                if case .line(_, let location, _, _) = row { highlights?[location] ?? [] } else { [] }
            cell.configure(with: row, gutterDigits: gutterDigits, tokens: tokens)
            return cell
        }

        func tableView(_ tableView: NSTableView, rowViewForRow index: Int) -> NSTableRowView? {
            let rowView: DiffTableRowView
            if let recycled = tableView.makeView(withIdentifier: Self.rowIdentifier, owner: nil) as? DiffTableRowView {
                rowView = recycled
            } else {
                rowView = DiffTableRowView()
                rowView.identifier = Self.rowIdentifier
            }

            rowView.tint = switch rows[index] {
            case .hunkHeader:
                DiffStyle.hunkHeaderBackground
            case .line(_, _, let line, _):
                switch line.kind {
                case .context: nil
                case .addition: DiffStyle.additionBackground
                case .deletion: DiffStyle.deletionBackground
                }
            }
            return rowView
        }
    }
}
