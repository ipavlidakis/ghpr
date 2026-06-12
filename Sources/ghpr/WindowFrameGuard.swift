import AppKit
import Foundation

/// Counters SwiftUI's hosting layer sporadically collapsing unbundled
/// windows to their minimum content size. The collapse is a startup race
/// that does not reliably post `didResizeNotification`, so the guard polls:
/// a half-second check per window costs nothing and cannot be evaded.
/// User drags (`inLiveResize`) are untouched, and `minSize` bounds those.
@MainActor
final class WindowFrameGuard {
    func protect(_ window: NSWindow, frame: NSRect) {
        Task { @MainActor [weak window] in
            while let window {
                if !window.inLiveResize, window.frame.width < 600 {
                    window.setFrame(frame, display: true)
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
}
