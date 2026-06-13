import AppKit
import Foundation

/// Objects that must stay alive for a native SwiftUI-hosting window.
@MainActor
final class WindowResources {
    /// Native window.
    let window: NSWindow
    /// Window delegate retained for the window lifetime.
    let delegate: WindowDelegate
    /// Toolbar delegate retained for the window lifetime.
    let toolbarDelegate: WindowToolbarDelegate

    /// Creates retained window resources.
    init(window: NSWindow, delegate: WindowDelegate, toolbarDelegate: WindowToolbarDelegate) {
        self.window = window
        self.delegate = delegate
        self.toolbarDelegate = toolbarDelegate
    }

    /// Presents the window.
    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}
