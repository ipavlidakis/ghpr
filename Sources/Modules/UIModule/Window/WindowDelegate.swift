import AppKit
import Foundation

/// Terminates the CLI process when the user closes the SwiftUI window.
final class WindowDelegate: NSObject, NSWindowDelegate {
    private let terminatesOnClose: Bool

    /// Creates a window delegate.
    init(terminatesOnClose: Bool = true) {
        self.terminatesOnClose = terminatesOnClose
    }

    /// Stops the app run loop when the window closes.
    func windowWillClose(_ notification: Notification) {
        if terminatesOnClose {
            NSApp.terminate(nil)
        }
    }
}
