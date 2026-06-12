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

    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)
        if let tint {
            tint.setFill()
            dirtyRect.fill(using: .sourceOver)
        }
    }
}
