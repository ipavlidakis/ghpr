import AppKit
import Foundation
import SwiftUI

/// Builds the native window toolbar used as the title bar surface.
final class WindowToolbarDelegate: NSObject, NSToolbarDelegate {
    private let title: String
    private let titleIdentifier = NSToolbarItem.Identifier("window.title")

    /// Creates a toolbar delegate for a window title.
    init(title: String) {
        self.title = title
    }

    /// Creates the toolbar that hosts the window title.
    @MainActor
    func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "window.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .default
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        return toolbar
    }

    @MainActor
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [titleIdentifier, .flexibleSpace]
    }

    @MainActor
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [titleIdentifier, .flexibleSpace]
    }

    @MainActor
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard itemIdentifier == titleIdentifier else {
            return nil
        }

        let titleView = NSHostingView(rootView: WindowTitleView(title: title))

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = titleView
        item.isBordered = false
        item.style = .plain
        return item
    }
}
