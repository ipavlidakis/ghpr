import Foundation
import SwiftTreeSitter

/// Background syntax highlighting with a per-file cache.
///
/// The diff never has the whole file, so highlighting is per-hunk
/// best-effort: each hunk side (old = context + deletions, new = context +
/// additions) is reconstructed as a fragment, parsed with the grammar's
/// error-tolerant parser, and the highlight captures are mapped back onto
/// individual diff lines.
package actor SyntaxHighlighter {
    private var cache: [String: FileSyntaxHighlights] = [:]
    private var configurations: [SupportedLanguage: LanguageConfiguration?] = [:]

    package init() {}

    /// Tokens for every line of the file, or `nil` when the language is
    /// unsupported or the file is binary.
    package func highlights(for fileDiff: FileDiff) -> FileSyntaxHighlights? {
        guard !fileDiff.isBinary, let language = SupportedLanguage(hint: fileDiff.languageHint) else {
            return nil
        }
        if let cached = cache[fileDiff.path] {
            return cached
        }
        guard
            let configuration = configuration(for: language),
            let query = configuration.queries[.highlights]
        else { return nil }

        let parser = Parser()
        guard (try? parser.setLanguage(configuration.language)) != nil else { return nil }

        var tokens: [LineLocation: [SyntaxToken]] = [:]
        for (hunkIndex, hunk) in fileDiff.hunks.enumerated() {
            if Task.isCancelled { return nil }
            highlight(hunk: hunk, at: hunkIndex, excluding: .deletion, parser: parser, query: query, into: &tokens)
            highlight(hunk: hunk, at: hunkIndex, excluding: .addition, parser: parser, query: query, into: &tokens)
        }

        let highlights = FileSyntaxHighlights(tokens: tokens)
        cache[fileDiff.path] = highlights
        return highlights
    }

    private func configuration(for language: SupportedLanguage) -> LanguageConfiguration? {
        if let cached = configurations[language] {
            return cached
        }
        let configuration = language.makeConfiguration()
        configurations[language] = configuration
        return configuration
    }

    /// Parses one side of a hunk and attributes the captures back to lines.
    private func highlight(
        hunk: DiffHunk,
        at hunkIndex: Int,
        excluding excluded: DiffLineKind,
        parser: Parser,
        query: Query,
        into tokens: inout [LineLocation: [SyntaxToken]]
    ) {
        var lineIndices: [Int] = []
        var lineStarts: [Int] = []
        var document = ""
        var offset = 0

        for (index, line) in hunk.lines.enumerated() where line.kind != excluded {
            // Context lines belong to both sides; attribute them to the new
            // side only so they are not highlighted twice.
            if line.kind == .context, excluded == .addition { continue }
            lineIndices.append(index)
            lineStarts.append(offset)
            document += line.text + "\n"
            offset += line.text.utf16.count + 1
        }
        guard !document.isEmpty, let tree = parser.parse(document) else { return }

        let cursor = query.execute(in: tree)
        let highlights = cursor
            .resolve(with: .init(string: document))
            .highlights()

        for namedRange in highlights {
            guard let kind = TokenKind(captureName: namedRange.name) else { continue }
            distribute(
                range: namedRange.range,
                kind: kind,
                hunkIndex: hunkIndex,
                lineIndices: lineIndices,
                lineStarts: lineStarts,
                lineLengths: lineIndices.map { hunk.lines[$0].text.utf16.count },
                into: &tokens
            )
        }
    }

    /// Clamps a document-wide capture range onto the lines it spans.
    private func distribute(
        range: NSRange,
        kind: TokenKind,
        hunkIndex: Int,
        lineIndices: [Int],
        lineStarts: [Int],
        lineLengths: [Int],
        into tokens: inout [LineLocation: [SyntaxToken]]
    ) {
        for (position, start) in lineStarts.enumerated() {
            let length = lineLengths[position]
            let lineRange = NSRange(location: start, length: length)
            guard let overlap = lineRange.intersection(range), overlap.length > 0 else { continue }

            let location = LineLocation(hunk: hunkIndex, line: lineIndices[position])
            let local = NSRange(location: overlap.location - start, length: overlap.length)
            tokens[location, default: []].append(SyntaxToken(range: local, kind: kind))
        }
    }
}
