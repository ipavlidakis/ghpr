import Foundation
import SwiftUI

/// Convenience construction for callers without inline annotations.
extension FileDiffView where Annotation == Never {
    /// A diff view with no inline annotations.
    package init(fileDiff: FileDiff) {
        self.init(fileDiff: fileDiff, annotation: { _ in nil })
    }
}
