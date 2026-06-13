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
            let collapseWidth = max(600, min(frame.width * 0.65, 840))
            while let window {
                if !window.inLiveResize, window.frame.width < collapseWidth {
                    window.setFrame(frame, display: true)
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
}
