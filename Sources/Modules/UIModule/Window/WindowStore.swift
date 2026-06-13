import AppKit
import Foundation

/// Retains open windows and their delegates while the app is running.
@MainActor
final class WindowStore {
    private var resources: [WindowResources] = []

    /// Retains resources for a visible window.
    func insert(_ resources: WindowResources) {
        self.resources.append(resources)
    }
}
