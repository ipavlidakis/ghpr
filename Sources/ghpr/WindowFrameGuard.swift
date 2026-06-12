import AppKit
import Foundation

/// Counters SwiftUI's early layout passes collapsing the unbundled window
/// to its minimum content size (observed with `NavigationSplitView` and
/// toolbar bridging). Watches resizes briefly after launch and restores the
/// intended frame, then stands down so the user can resize freely.
@MainActor
final class WindowFrameGuard {
    func protect(_ window: NSWindow, frame: NSRect, for duration: Duration) {
        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak window] _ in
            MainActor.assumeIsolated {
                guard let window, window.frame.width < 600 else { return }
                window.setFrame(frame, display: true)
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: duration)
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
