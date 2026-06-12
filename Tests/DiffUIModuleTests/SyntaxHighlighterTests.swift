import Foundation
import Testing
import DiffUIModule

/// Highlights real Swift hunks through the bundled grammar.
@Suite("SyntaxHighlighter")
struct SyntaxHighlighterTests {
    private let highlighter = SyntaxHighlighter()

    private func swiftFile(lines: [DiffLine]) -> FileDiff {
        FileDiff(
            path: "Sources/Example.swift",
            status: .modified,
            hunks: [DiffHunk(header: "@@ -1,\(lines.count) +1,\(lines.count) @@", oldStart: 1, oldCount: lines.count, newStart: 1, newCount: lines.count, lines: lines)]
        )
    }

    @Test("keywords in added Swift code are tokenized")
    func swiftKeywords() async throws {
        let file = swiftFile(lines: [
            DiffLine(kind: .context, text: "import Foundation", oldLineNumber: 1, newLineNumber: 1),
            DiffLine(kind: .addition, text: "func greet(name: String) -> String {", oldLineNumber: nil, newLineNumber: 2),
            DiffLine(kind: .addition, text: "    return \"hello \\(name)\"", oldLineNumber: nil, newLineNumber: 3),
            DiffLine(kind: .addition, text: "}", oldLineNumber: nil, newLineNumber: 4),
        ])

        let highlights = try #require(await highlighter.highlights(for: file))

        let funcLine = highlights[LineLocation(hunk: 0, line: 1)]
        let keywordToken = try #require(funcLine.first { $0.kind == .keyword })
        let funcLineText = "func greet(name: String) -> String {" as NSString
        #expect(funcLineText.substring(with: keywordToken.range) == "func")

        let stringLine = highlights[LineLocation(hunk: 0, line: 2)]
        #expect(stringLine.contains { $0.kind == .string })
    }

    @Test("deleted lines are highlighted from the old side")
    func deletedSide() async throws {
        let file = swiftFile(lines: [
            DiffLine(kind: .deletion, text: "let answer = 42", oldLineNumber: 1, newLineNumber: nil),
            DiffLine(kind: .addition, text: "let answer = 43", oldLineNumber: nil, newLineNumber: 1),
        ])

        let highlights = try #require(await highlighter.highlights(for: file))

        #expect(highlights[LineLocation(hunk: 0, line: 0)].contains { $0.kind == .keyword })
        #expect(highlights[LineLocation(hunk: 0, line: 1)].contains { $0.kind == .keyword })
    }

    @Test("unsupported languages produce no highlights")
    func unsupportedLanguage() async {
        let file = FileDiff(path: "image.xcassets", status: .modified, hunks: [])

        #expect(await highlighter.highlights(for: file) == nil)
    }
}
