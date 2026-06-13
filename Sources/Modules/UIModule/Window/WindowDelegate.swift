import AppKit
import Foundation

/// Terminates the CLI process when the user closes the SwiftUI window.
final class WindowDelegate: NSObject, NSWindowDelegate {
    /// Stops the app run loop when the window closes.
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}
