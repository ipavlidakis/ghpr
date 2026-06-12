import Foundation

/// One caller-defined entry of a file header's "…" menu. The module renders
/// the menu; what the actions do (open GitHub, etc.) is the caller's world.
package struct DiffFileAction: Sendable {
    package let title: String
    package let handler: @MainActor @Sendable (String) -> Void

    package init(title: String, handler: @escaping @MainActor @Sendable (String) -> Void) {
        self.title = title
        self.handler = handler
    }
}
