import Foundation

/// How a file changed within a diff.
package enum FileDiffStatus: Sendable, Equatable, Hashable {
    case added
    case deleted
    case modified
    case renamed(from: String)
}
