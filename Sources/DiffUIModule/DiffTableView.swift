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
///
/// Annotation rows (review threads) are the exception: they host SwiftUI
/// content at caller-defined heights, measured per row.
struct DiffTableView: NSViewRepresentable {
    let rows: [DiffRow]
    let gutterDigits: Int
    let highlights: FileSyntaxHighlights?
    let annotations: [DiffLineAnchor: AnyView]
    var onLineClick: ((DiffLine) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: rows, gutterDigits: gutterDigits, highlights: highlights, annotations: annotations, onLineClick: onLineClick)
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

        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tableClicked(_:)))
        tableView.addGestureRecognizer(click)

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.update(rows: rows, gutterDigits: gutterDigits, highlights: highlights, annotations: annotations, onLineClick: onLineClick)
        (scrollView.documentView as? NSTableView)?.reloadData()
    }

    /// Data source and delegate vending recycled, fixed-height line cells and
    /// measured annotation cells.
    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        static let columnIdentifier = NSUserInterfaceItemIdentifier("diffLine")
        private static let cellIdentifier = NSUserInterfaceItemIdentifier("diffLineCell")
        private static let rowIdentifier = NSUserInterfaceItemIdentifier("diffRow")

        private var rows: [DiffRow]
        private var gutterDigits: Int
        private var highlights: FileSyntaxHighlights?
        private var annotations: [DiffLineAnchor: AnyView]
        private var onLineClick: ((DiffLine) -> Void)?
        private var annotationCells: [DiffLineAnchor: DiffAnnotationCellView] = [:]

        init(
            rows: [DiffRow],
            gutterDigits: Int,
            highlights: FileSyntaxHighlights?,
            annotations: [DiffLineAnchor: AnyView],
            onLineClick: ((DiffLine) -> Void)?
        ) {
            self.rows = rows
            self.gutterDigits = gutterDigits
            self.highlights = highlights
            self.annotations = annotations
            self.onLineClick = onLineClick
        }

        func update(
            rows: [DiffRow],
            gutterDigits: Int,
            highlights: FileSyntaxHighlights?,
            annotations: [DiffLineAnchor: AnyView],
            onLineClick: ((DiffLine) -> Void)?
        ) {
            self.rows = rows
            self.gutterDigits = gutterDigits
            self.highlights = highlights
            self.annotations = annotations
            self.onLineClick = onLineClick
            annotationCells.removeAll()
        }

        @objc func tableClicked(_ recognizer: NSClickGestureRecognizer) {
            guard
                let onLineClick,
                let tableView = recognizer.view as? NSTableView
            else { return }

            let index = tableView.row(at: recognizer.location(in: tableView))
            guard index >= 0, case .line(_, _, let line, _) = rows[index] else { return }
            onLineClick(line)
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            rows.count
        }

        func tableView(_ tableView: NSTableView, heightOfRow index: Int) -> CGFloat {
            switch rows[index] {
            case .hunkHeader, .line:
                DiffStyle.rowHeight
            case .annotation(_, let anchor):
                annotationCell(for: anchor).map { $0.height(forWidth: tableView.bounds.width) + 8 } ?? 0
            }
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row index: Int) -> NSView? {
            switch rows[index] {
            case .hunkHeader, .line:
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
            case .annotation(_, let anchor):
                return annotationCell(for: anchor)
            }
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
            case .annotation:
                nil
            case .line(_, _, let line, _):
                switch line.kind {
                case .context: nil
                case .addition: DiffStyle.additionBackground
                case .deletion: DiffStyle.deletionBackground
                }
            }
            return rowView
        }

        private func annotationCell(for anchor: DiffLineAnchor) -> DiffAnnotationCellView? {
            if let cell = annotationCells[anchor] {
                return cell
            }
            guard let content = annotations[anchor] else { return nil }
            let cell = DiffAnnotationCellView(content: content)
            annotationCells[anchor] = cell
            return cell
        }
    }
}
