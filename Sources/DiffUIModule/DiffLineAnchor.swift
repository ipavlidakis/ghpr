import Foundation

/// Addresses a diff line by side and line number — the way external systems
/// (review threads) anchor content to a diff.
package enum DiffLineAnchor: Sendable, Hashable {
    case old(Int)
    case new(Int)
}
