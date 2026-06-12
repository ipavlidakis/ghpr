import Foundation
import SwiftUI

/// Caller content pinned under a diff line, with an explicit content version.
///
/// The table only reloads when its content fingerprint changes; `AnyView`
/// cannot be hashed, so callers bump `version` whenever the content's
/// meaning changes (collapse toggled, comment added) to invalidate the
/// cached cell and its measured height.
package struct DiffAnnotation {
    package let version: Int
    package let content: AnyView

    package init(version: Int, content: AnyView) {
        self.version = version
        self.content = content
    }
}
