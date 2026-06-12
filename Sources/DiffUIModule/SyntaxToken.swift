import Foundation

/// One colored span within a single diff line.
package struct SyntaxToken: Sendable, Equatable {
    /// UTF-16 range within the line's text.
    package let range: NSRange
    package let kind: TokenKind

    package init(range: NSRange, kind: TokenKind) {
        self.range = range
        self.kind = kind
    }
}
