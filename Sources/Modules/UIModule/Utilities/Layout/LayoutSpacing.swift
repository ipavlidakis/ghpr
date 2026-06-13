import CoreGraphics
import Foundation

/// Uniform spacing scale for compact macOS UI surfaces.
package struct LayoutSpacing: Sendable {
    /// No spacing between tightly joined surfaces.
    package let xsmall: CGFloat
    /// Compact spacing for small controls and metadata.
    package let small: CGFloat
    /// Standard spacing for rows and nearby controls.
    package let medium: CGFloat
    /// Section spacing for outer content edges.
    package let large: CGFloat
    package let xlarge: CGFloat

    /// Creates the default 4-point based spacing scale.
    package init() {
        xsmall = 0
        small = 4
        medium = 8
        large = 12
        xlarge = 16
    }
}
