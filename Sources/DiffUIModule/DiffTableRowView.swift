import AppKit
import Foundation

/// Full-width tinted background for diff rows.
///
/// `NSTableView` overwrites `backgroundColor` on row views while preparing
/// them, so the tint is drawn explicitly instead of assigned.
final class DiffTableRowView: NSTableRowView {
    var tint: NSColor? {
        didSet { needsDisplay = true }
    }

    /// Part of the user's line-granular text selection.
    var isInSelectedRange = false {
        didSet {
            if isInSelectedRange != oldValue {
                needsDisplay = true
            }
        }
    }

    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)
        if let tint {
            tint.setFill()
            dirtyRect.fill(using: .sourceOver)
        }
        if isInSelectedRange {
            NSColor.selectedContentBackgroundColor.withAlphaComponent(0.35).setFill()
            dirtyRect.fill(using: .sourceOver)
        }
    }
}
