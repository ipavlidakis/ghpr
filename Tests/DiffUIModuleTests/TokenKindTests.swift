import Foundation
import Testing
import DiffUIModule

/// Covers capture-name to token-kind mapping, including dotted captures.
@Suite("TokenKind capture mapping")
struct TokenKindTests {
    @Test(
        "known captures map to kinds",
        arguments: [
            ("keyword", TokenKind.keyword),
            ("keyword.function", .keyword),
            ("string.special", .string),
            ("comment.documentation", .comment),
            ("number", .number),
            ("type.builtin", .type),
            ("function.call", .function),
            ("variable.builtin", .property),
            ("attribute", .attribute),
        ]
    )
    func knownCaptures(capture: String, expected: TokenKind) {
        #expect(TokenKind(captureName: capture) == expected)
    }

    @Test("unknown captures map to nothing")
    func unknownCaptures() {
        #expect(TokenKind(captureName: "punctuation.bracket") == nil)
        #expect(TokenKind(captureName: "") == nil)
    }
}
