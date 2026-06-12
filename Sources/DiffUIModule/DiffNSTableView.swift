import AppKit
import Foundation

/// Table subclass owning line-granular text selection: dragging across code
/// rows selects them, cmd-C copies their text. Field-level selection cannot
/// span recycled rows, so selection is whole lines by design.
final class DiffNSTableView: NSTableView {
    /// Whether the row at an index is selectable code (not a header).
    var isSelectableRow: ((Int) -> Bool)?
    /// Reports every selection change for row repainting.
    var onSelectionChange: ((ClosedRange<Int>?) -> Void)?
    /// Copies the current selection to the pasteboard.
    var onCopySelection: (() -> Void)?

    private var anchorRow: Int?

    private(set) var selectedRange: ClosedRange<Int>? {
        didSet {
            if selectedRange != oldValue {
                onSelectionChange?(selectedRange)
            }
        }
    }

    override var acceptsFirstResponder: Bool { true }

    func clearLineSelection() {
        anchorRow = nil
        selectedRange = nil
    }

    override func mouseDown(with event: NSEvent) {
        let index = row(at: convert(event.locationInWindow, from: nil))
        if index >= 0, isSelectableRow?(index) == true {
            window?.makeFirstResponder(self)
            anchorRow = index
            selectedRange = index...index
            // The drag is ours; super would start the table's own tracking.
        } else {
            clearLineSelection()
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let anchorRow else {
            super.mouseDragged(with: event)
            return
        }
        autoscroll(with: event)
        let index = row(at: convert(event.locationInWindow, from: nil))
        guard index >= 0 else { return }
        selectedRange = min(anchorRow, index)...max(anchorRow, index)
    }

    override func mouseUp(with event: NSEvent) {
        if anchorRow == nil {
            super.mouseUp(with: event)
        }
        anchorRow = nil
    }

    /// Reached via the Edit menu's Copy (`copy:`) through the responder chain.
    @objc func copy(_ sender: Any?) {
        onCopySelection?()
    }

    /// The standard text-selection context menu: right-clicking inside the
    /// selection offers Copy; right-clicking an unselected code line first
    /// moves the selection there, like any macOS text view.
    override func menu(for event: NSEvent) -> NSMenu? {
        let index = row(at: convert(event.locationInWindow, from: nil))
        guard index >= 0, isSelectableRow?(index) == true else {
            return super.menu(for: event)
        }

        if selectedRange?.contains(index) != true {
            selectedRange = index...index
        }

        let menu = NSMenu()
        let copyItem = NSMenuItem(title: "Copy", action: #selector(copy(_:)), keyEquivalent: "")
        copyItem.target = self
        menu.addItem(copyItem)
        return menu
    }

    override func cancelOperation(_ sender: Any?) {
        clearLineSelection()
    }
}
