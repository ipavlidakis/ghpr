import Foundation

/// All syntax tokens of one file's diff, keyed by line location.
package struct FileSyntaxHighlights: Sendable, Equatable {
    package let tokens: [LineLocation: [SyntaxToken]]

    package init(tokens: [LineLocation: [SyntaxToken]]) {
        self.tokens = tokens
    }

    package subscript(location: LineLocation) -> [SyntaxToken] {
        tokens[location] ?? []
    }
}
