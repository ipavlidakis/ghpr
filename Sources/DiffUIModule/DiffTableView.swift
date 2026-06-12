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
///
/// In multi-file mode the table also reports which file owns the topmost
/// visible row and honors scroll-to-file requests, so a sidebar can follow.
struct DiffTableView: NSViewRepresentable {
    let rows: [DiffRow]
    let gutterDigits: Int
    let highlightsByFile: [String: FileSyntaxHighlights]
    let annotations: [DiffFileAnchor: AnyView]
    var onLineClick: ((String, DiffLine) -> Void)?
    var onFileHeaderClick: ((String) -> Void)?
    var onVisibleFileChange: ((String) -> Void)?
    var scrollTarget: DiffScrollTarget?

    func makeCoordinator() -> Coordinator {
        Coordinator()
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

        context.coordinator.observeScrolling(of: scrollView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.apply(self, to: scrollView)
    }

    /// Data source and delegate vending recycled, fixed-height line cells and
    /// measured annotation cells.
    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        static let columnIdentifier = NSUserInterfaceItemIdentifier("diffLine")
        private static let cellIdentifier = NSUserInterfaceItemIdentifier("diffLineCell")
        private static let fileHeaderIdentifier = NSUserInterfaceItemIdentifier("diffFileHeaderCell")
        private static let rowIdentifier = NSUserInterfaceItemIdentifier("diffRow")

        private var view: DiffTableView?
        private var annotationCells: [DiffFileAnchor: DiffAnnotationCellView] = [:]
        private var lastReportedFile: String?
        private var lastScrollToken: UUID?
        private var lastReloadFingerprint: Int?

        private var rows: [DiffRow] { view?.rows ?? [] }

        // MARK: Updates

        func apply(_ newView: DiffTableView, to scrollView: NSScrollView) {
            let oldFingerprint = lastReloadFingerprint
            view = newView

            guard let tableView = scrollView.documentView as? NSTableView else { return }

            let fingerprint = newView.contentFingerprint
            if fingerprint != oldFingerprint {
                lastReloadFingerprint = fingerprint
                annotationCells.removeAll()
                tableView.reloadData()
            }

            if let target = newView.scrollTarget, target.token != lastScrollToken {
                lastScrollToken = target.token
                scroll(to: target.path, in: scrollView)
            }
        }

        // MARK: Scroll following

        func observeScrolling(of scrollView: NSScrollView) {
            scrollView.contentView.postsBoundsChangedNotifications = true
            // Selector-based observers are removed automatically on dealloc.
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(boundsDidChange(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        }

        @objc private func boundsDidChange(_ notification: Notification) {
            guard
                let clipView = notification.object as? NSClipView,
                let scrollView = clipView.superview as? NSScrollView
            else { return }
            reportVisibleFile(in: scrollView)
        }

        private func reportVisibleFile(in scrollView: NSScrollView) {
            guard
                let onVisibleFileChange = view?.onVisibleFileChange,
                let tableView = scrollView.documentView as? NSTableView
            else { return }

            let visible = tableView.rows(in: tableView.visibleRect)
            guard visible.length > 0 else { return }

            // Walk back from the topmost visible row to the owning file.
            var index = visible.location
            var path: String?
            while index >= 0 {
                if let filePath = rows[index].filePath {
                    path = filePath
                    break
                }
                index -= 1
            }

            guard let path, path != lastReportedFile else { return }
            lastReportedFile = path
            onVisibleFileChange(path)
        }

        private func scroll(to path: String, in scrollView: NSScrollView) {
            guard
                let tableView = scrollView.documentView as? NSTableView,
                let index = rows.firstIndex(where: {
                    if case .fileHeader(_, let file, _) = $0 { file.path == path } else { false }
                })
            else { return }

            // Pin the file header to the top of the viewport.
            lastReportedFile = path
            let rect = tableView.rect(ofRow: index)
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: rect.minY))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }

        // MARK: Clicks

        @objc func tableClicked(_ recognizer: NSClickGestureRecognizer) {
            guard let tableView = recognizer.view as? NSTableView else { return }

            let index = tableView.row(at: recognizer.location(in: tableView))
            guard index >= 0 else { return }

            switch rows[index] {
            case .line(_, let file, _, let line, _):
                view?.onLineClick?(file, line)
            case .fileHeader(_, let file, _):
                view?.onFileHeaderClick?(file.path)
            case .hunkHeader, .annotation:
                break
            }
        }

        // MARK: Table data

        func numberOfRows(in tableView: NSTableView) -> Int {
            rows.count
        }

        func tableView(_ tableView: NSTableView, heightOfRow index: Int) -> CGFloat {
            switch rows[index] {
            case .fileHeader:
                26
            case .hunkHeader, .line:
                DiffStyle.rowHeight
            case .annotation(_, let anchor):
                annotationCell(for: anchor).map { $0.height(forWidth: tableView.bounds.width) + 8 } ?? 0
            }
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row index: Int) -> NSView? {
            switch rows[index] {
            case .fileHeader(_, let file, let isCollapsed):
                let cell: DiffFileHeaderCellView
                if let recycled = tableView.makeView(withIdentifier: Self.fileHeaderIdentifier, owner: nil) as? DiffFileHeaderCellView {
                    cell = recycled
                } else {
                    cell = DiffFileHeaderCellView()
                    cell.identifier = Self.fileHeaderIdentifier
                }
                cell.configure(with: file, isCollapsed: isCollapsed)
                return cell
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
                    if case .line(_, let file, let location, _, _) = row {
                        view?.highlightsByFile[file]?[location] ?? []
                    } else { [] }
                cell.configure(with: row, gutterDigits: view?.gutterDigits ?? 3, tokens: tokens)
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
            case .fileHeader:
                DiffStyle.fileHeaderBackground
            case .hunkHeader:
                DiffStyle.hunkHeaderBackground
            case .annotation:
                nil
            case .line(_, _, _, let line, _):
                switch line.kind {
                case .context: nil
                case .addition: DiffStyle.additionBackground
                case .deletion: DiffStyle.deletionBackground
                }
            }
            return rowView
        }

        private func annotationCell(for anchor: DiffFileAnchor) -> DiffAnnotationCellView? {
            if let cell = annotationCells[anchor] {
                return cell
            }
            guard let content = view?.annotations[anchor] else { return nil }
            let cell = DiffAnnotationCellView(content: content)
            annotationCells[anchor] = cell
            return cell
        }
    }
}