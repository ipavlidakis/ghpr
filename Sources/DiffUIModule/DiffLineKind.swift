import Foundation

/// The role of a single line within a hunk.
package enum DiffLineKind: Sendable, Equatable {
    case context
    case addition
    case deletion
}
