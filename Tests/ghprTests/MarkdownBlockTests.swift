import Foundation
import Testing
@testable import ghpr

/// Covers block parsing, including GitHub's CRLF line endings.
@Suite("MarkdownBlock")
struct MarkdownBlockTests {
    @Test("a real CRLF PR body parses every heading")
    func realBody() throws {
        let url = try #require(Bundle.module.url(forResource: "pr-body", withExtension: "md", subdirectory: "Fixtures"))
        let body = try String(contentsOf: url, encoding: .utf8)

        let blocks = MarkdownBlock.parse(body)

        let headings = blocks.compactMap { block -> String? in
            if case .heading(_, let text) = block { text } else { nil }
        }
        #expect(headings.contains { $0.hasPrefix("Motivation") })
        #expect(headings.contains { $0.hasPrefix("Modifications") })
        #expect(headings.contains { $0.hasPrefix("Result") })

        for case .paragraph(let text) in blocks {
            #expect(!text.contains("###"), "heading leaked into a paragraph: \(text.prefix(60))")
        }
    }

    @Test("blocks parse: headings, lists, fences, quotes, rules")
    func basics() {
        let text = """
        # Title
        intro line

        - one
        - two

        ```swift
        let x = 1
        ```

        > quoted

        ---
        tail
        """

        let blocks = MarkdownBlock.parse(text)

        #expect(blocks == [
            .heading(level: 1, text: "Title"),
            .paragraph("intro line"),
            .bullets(["one", "two"]),
            .code("let x = 1"),
            .quote("quoted"),
            .rule,
            .paragraph("tail"),
        ])
    }

    @Test("CRLF blank lines still separate paragraphs")
    func crlf() {
        let text = "first\r\n\r\nsecond\r\n### Head\r\nafter"

        let blocks = MarkdownBlock.parse(text)

        #expect(blocks == [
            .paragraph("first"),
            .paragraph("second"),
            .heading(level: 3, text: "Head"),
            .paragraph("after"),
        ])
    }
}
