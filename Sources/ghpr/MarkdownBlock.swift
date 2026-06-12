import Foundation

/// Block-level structure of a markdown document. `AttributedString`'s full
/// markdown parsing produces presentation intents SwiftUI ignores, so block
/// layout (headings, lists, fences, tables, details) is parsed here and
/// styled natively; inline styling stays with `AttributedString`.
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case code(String)
    case bullets([String])
    case quote(String)
    case rule
    case table(header: [String], rows: [[String]])
    /// A `<details>` disclosure with its `<summary>` label, as bot comments
    /// use heavily. HTML comments and `<blockquote>` tags are stripped.
    indirect case details(summary: String, blocks: [MarkdownBlock])

    static func parse(_ text: String) -> [MarkdownBlock] {
        // GitHub bodies use CRLF; "\r\n" is a single grapheme in Swift, so
        // splitting on "\n" without normalizing would never split at all.
        let text = text.replacingOccurrences(of: "\r\n", with: "\n")
        return parse(lines: text.components(separatedBy: "\n"))
    }

    private static func parse(lines: [String]) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var bullets: [String] = []
        var codeLines: [String] = []
        var inCodeFence = false
        var inHTMLComment = false

        func flushParagraph() {
            if !paragraph.isEmpty {
                blocks.append(.paragraph(paragraph.joined(separator: "\n")))
                paragraph = []
            }
        }

        func flushBullets() {
            if !bullets.isEmpty {
                blocks.append(.bullets(bullets))
                bullets = []
            }
        }

        var index = 0
        while index < lines.count {
            let current = index
            index += 1

            var line = lines[current]
            var trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if inCodeFence {
                    blocks.append(.code(codeLines.joined(separator: "\n")))
                    codeLines = []
                } else {
                    flushParagraph()
                    flushBullets()
                }
                inCodeFence.toggle()
                continue
            }
            if inCodeFence {
                codeLines.append(line)
                continue
            }

            // GitHub hides HTML comments entirely.
            if inHTMLComment {
                if line.contains("-->") { inHTMLComment = false }
                continue
            }
            if trimmed.hasPrefix("<!--") {
                if !trimmed.contains("-->") { inHTMLComment = true }
                continue
            }

            // Presentational wrappers bots emit around details content.
            if trimmed.contains("<") {
                for tag in ["<blockquote>", "</blockquote>", "<sub>", "</sub>", "<sup>", "</sup>"] {
                    line = line.replacingOccurrences(of: tag, with: "", options: .caseInsensitive)
                }
                trimmed = line.trimmingCharacters(in: .whitespaces)
            }

            if trimmed.lowercased().hasPrefix("<details") {
                flushParagraph()
                flushBullets()
                // Consume up to the matching close, allowing nesting.
                var depth = 0
                var end = current
                while end < lines.count {
                    let scanned = lines[end].lowercased()
                    depth += scanned.components(separatedBy: "<details").count - 1
                    depth -= scanned.components(separatedBy: "</details>").count - 1
                    end += 1
                    if depth <= 0 { break }
                }
                blocks.append(detailsBlock(Array(lines[current..<end])))
                index = end
                continue
            }

            if trimmed.hasPrefix("|"), index < lines.count, isTableSeparator(lines[index]) {
                flushParagraph()
                flushBullets()
                let header = tableCells(trimmed)
                var rows: [[String]] = []
                var cursor = index + 1
                while cursor < lines.count {
                    let row = lines[cursor].trimmingCharacters(in: .whitespaces)
                    guard row.hasPrefix("|") else { break }
                    rows.append(tableCells(row))
                    cursor += 1
                }
                blocks.append(.table(header: header, rows: rows))
                index = cursor
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                flushBullets()
            } else if let heading = headingLevel(of: trimmed) {
                flushParagraph()
                flushBullets()
                blocks.append(.heading(level: heading.level, text: heading.text))
            } else if trimmed == "---" || trimmed == "***" {
                flushParagraph()
                flushBullets()
                blocks.append(.rule)
            } else if let item = bulletItem(of: trimmed) {
                flushParagraph()
                bullets.append(item)
            } else if trimmed.hasPrefix("> ") {
                flushParagraph()
                flushBullets()
                blocks.append(.quote(String(trimmed.dropFirst(2))))
            } else if !bullets.isEmpty {
                // Continuation of the previous list item.
                bullets[bullets.count - 1] += " " + trimmed
            } else {
                paragraph.append(line)
            }
        }

        if inCodeFence, !codeLines.isEmpty {
            blocks.append(.code(codeLines.joined(separator: "\n")))
        }
        flushParagraph()
        flushBullets()
        return blocks
    }

    // MARK: Details

    private static func detailsBlock(_ segment: [String]) -> MarkdownBlock {
        var text = segment.joined(separator: "\n")

        if let open = text.range(of: "<details[^>]*>", options: [.regularExpression, .caseInsensitive]) {
            text.removeSubrange(open)
        }
        if let close = text.range(of: "</details>", options: [.backwards, .caseInsensitive]) {
            text.removeSubrange(close)
        }

        var summary = "Details"
        if let range = text.range(of: "(?s)<summary>.*?</summary>", options: [.regularExpression, .caseInsensitive]) {
            summary = String(text[range])
                .replacingOccurrences(of: "<summary>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "</summary>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "<blockquote>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "</blockquote>", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            text.removeSubrange(range)
        }

        return .details(summary: summary, blocks: parse(lines: text.components(separatedBy: "\n")))
    }

    // MARK: Tables

    /// `| --- | :--: |` and the compact `|-|-|` form.
    private static func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|"), trimmed.contains("-") else { return false }
        return trimmed.allSatisfy { "|-: \t".contains($0) }
    }

    private static func tableCells(_ line: String) -> [String] {
        var content = line
        if content.hasPrefix("|") { content.removeFirst() }
        if content.hasSuffix("|") { content.removeLast() }
        return content.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func headingLevel(of line: String) -> (level: Int, text: String)? {
        let hashes = line.prefix(while: { $0 == "#" })
        guard (1...6).contains(hashes.count) else { return nil }
        let rest = line.dropFirst(hashes.count)
        guard rest.hasPrefix(" ") else { return nil }
        return (hashes.count, rest.trimmingCharacters(in: .whitespaces))
    }

    private static func bulletItem(of line: String) -> String? {
        for marker in ["- ", "* ", "+ "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count))
        }
        if let dot = line.firstIndex(of: "."),
           line[line.startIndex..<dot].allSatisfy(\.isNumber),
           !line[line.startIndex..<dot].isEmpty,
           line[line.index(after: dot)...].hasPrefix(" ") {
            return String(line[line.index(dot, offsetBy: 2)...])
        }
        return nil
    }
}
