import AppKit
import Foundation

/// Convenience for building the programmatic main menu.
extension NSMenu {
    func addItem(submenu: NSMenu) {
        let item = NSMenuItem()
        item.submenu = submenu
        addItem(item)
    }
}
