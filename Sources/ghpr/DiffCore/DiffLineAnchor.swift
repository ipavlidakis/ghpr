import Foundation

/// Addresses a diff line by side and line number.
package enum DiffLineAnchor: Sendable, Hashable {
    case old(Int)
    case new(Int)
}
