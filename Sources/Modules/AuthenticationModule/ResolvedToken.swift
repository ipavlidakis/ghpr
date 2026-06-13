import Foundation

/// A GitHub token together with where it came from.
package struct ResolvedToken: Sendable, Equatable {
    package let value: String
    package let source: TokenSource

    package init(value: String, source: TokenSource) {
        self.value = value
        self.source = source
    }
}
