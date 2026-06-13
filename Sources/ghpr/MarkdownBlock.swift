import Foundation

/// Block-level structure of a markdown document. `AttributedString`'s full
/// markdown parsing omits some block structure here, so layout (headings,
/// lists, fences, tables, details) is parsed explicitly and inline styling
/// stays with `AttributedString`.
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case rightAlignedParagraph(String)
    case code(language: String?, text: String)
    case bullets([String])
    case task(checked: Bool, text: String)
    case quote(String)
    indirect case alert(kind: String, blocks: [MarkdownBlock])
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
        var codeLanguage: String?
        var inCodeFence = false
        var inHTMLComment = false

        func flushParagraph() {
            if !paragraph.isEmpty {
                for line in paragraph {
                    blocks.append(.paragraph(emojiShortcodes(in: line)))
                }
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
                    blocks.append(.code(language: codeLanguage, text: codeLines.joined(separator: "\n")))
                    codeLines = []
                    codeLanguage = nil
                } else {
                    flushParagraph()
                    flushBullets()
                    let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeLanguage = language.isEmpty ? nil : language.lowercased()
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
            if line.contains("<!--") {
                line = stripInlineHTMLComments(line)
                trimmed = line.trimmingCharacters(in: .whitespaces)
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

            if trimmed.lowercased().hasPrefix("<p"), trimmed.lowercased().contains(#"align="right""#) {
                flushParagraph()
                flushBullets()
                var end = current
                while end < lines.count {
                    end += 1
                    if lines[end - 1].lowercased().contains("</p>") { break }
                }
                let text = plainHTMLText(lines[current..<end].joined(separator: "\n"))
                if !text.isEmpty {
                    blocks.append(.rightAlignedParagraph(text))
                }
                index = end
                continue
            }

            if trimmed.lowercased().hasPrefix("<table") {
                flushParagraph()
                flushBullets()
                var end = current
                while end < lines.count {
                    end += 1
                    if lines[end - 1].lowercased().contains("</table>") { break }
                }
                blocks.append(htmlTableBlock(Array(lines[current..<end])))
                index = end
                continue
            }

            if index < lines.count, tableCells(trimmed).count > 1, isTableSeparator(lines[index]) {
                flushParagraph()
                flushBullets()
                let header = tableCells(trimmed)
                var rows: [[String]] = []
                var cursor = index + 1
                while cursor < lines.count {
                    let row = lines[cursor].trimmingCharacters(in: .whitespaces)
                    guard !row.isEmpty, row.contains("|") else { break }
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
                blocks.append(.heading(level: heading.level, text: emojiShortcodes(in: heading.text)))
            } else if trimmed == "---" || trimmed == "***" {
                flushParagraph()
                flushBullets()
                blocks.append(.rule)
            } else if isQuoteLine(trimmed) {
                flushParagraph()
                flushBullets()
                var quoteLines = [unquotedLine(line)]
                while index < lines.count {
                    let quoteLine = lines[index]
                    guard isQuoteLine(quoteLine.trimmingCharacters(in: .whitespaces)) else { break }
                    quoteLines.append(unquotedLine(quoteLine))
                    index += 1
                }
                blocks.append(quoteBlock(quoteLines))
            } else if let task = taskItem(of: trimmed) {
                flushParagraph()
                flushBullets()
                blocks.append(.task(checked: task.checked, text: task.text))
            } else if let item = bulletItem(of: trimmed) {
                flushParagraph()
                bullets.append(emojiShortcodes(in: item))
            } else if !bullets.isEmpty {
                // Continuation of the previous list item.
                bullets[bullets.count - 1] += " " + emojiShortcodes(in: trimmed)
            } else {
                if line.contains("<") {
                    line = plainHTMLText(line)
                }
                if !line.isEmpty {
                    paragraph.append(emojiShortcodes(in: line))
                }
            }
        }

        if inCodeFence, !codeLines.isEmpty {
            blocks.append(.code(language: codeLanguage, text: codeLines.joined(separator: "\n")))
        }
        flushParagraph()
        flushBullets()
        return blocks
    }

    // MARK: Details

    private static func quoteBlock(_ lines: [String]) -> MarkdownBlock {
        guard let firstContentIndex = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            return .quote("")
        }

        let first = lines[firstContentIndex].trimmingCharacters(in: .whitespaces)
        if first.hasPrefix("[!"), first.hasSuffix("]") {
            let kind = String(first.dropFirst(2).dropLast()).lowercased()
            var body = lines
            body.removeSubrange(0...firstContentIndex)
            return .alert(kind: kind, blocks: parse(lines: body))
        }

        return .quote(emojiShortcodes(in: lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    private static func isQuoteLine(_ line: String) -> Bool {
        line == ">" || line.hasPrefix("> ")
    }

    private static func unquotedLine(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed == ">" { return "" }
        if trimmed.hasPrefix("> ") { return String(trimmed.dropFirst(2)) }
        return line
    }

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
            summary = emojiShortcodes(in: String(text[range])
                .replacingOccurrences(of: "<summary>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "</summary>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "<blockquote>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "</blockquote>", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines))
            text.removeSubrange(range)
        }

        return .details(summary: summary, blocks: parse(lines: text.components(separatedBy: "\n")))
    }

    // MARK: Tables

    private static func htmlTableBlock(_ segment: [String]) -> MarkdownBlock {
        let table = segment.joined(separator: "\n")
        let rows = regexMatches(#"(?is)<tr[^>]*>(.*?)</tr>"#, in: table)
            .map { rowHTML in
                regexMatches(#"(?is)<t[dh][^>]*>(.*?)</t[dh]>"#, in: rowHTML)
                    .map(plainHTMLText)
            }
            .filter { !$0.isEmpty }

        guard let header = rows.first else {
            return .paragraph(plainHTMLText(table))
        }
        return .table(header: header, rows: Array(rows.dropFirst()))
    }

    /// `| --- | :--: |`, `--- | :---:`, and the compact `|-|-|` form.
    private static func isTableSeparator(_ line: String) -> Bool {
        let cells = tableCells(line)
        guard cells.count > 1 else { return false }
        return cells.allSatisfy { cell in
            cell.contains("-") && cell.allSatisfy { "-: \t".contains($0) }
        }
    }

    private static func tableCells(_ line: String) -> [String] {
        var content = line
        if content.hasPrefix("|") { content.removeFirst() }
        if content.hasSuffix("|") { content.removeLast() }
        return content.components(separatedBy: "|").map {
            tableCellText($0.trimmingCharacters(in: .whitespaces))
        }
    }

    private static func tableCellText(_ text: String) -> String {
        emojiShortcodes(in: text
            .replacingOccurrences(of: #"(?i)<br\s*/?>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'"))
    }

    private static func regexMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    private static func plainHTMLText(_ html: String) -> String {
        emojiShortcodes(in: html
            .replacingOccurrences(of: #"(?is)<!--.*?-->"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)<br\s*/?>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func stripInlineHTMLComments(_ text: String) -> String {
        text.replacingOccurrences(of: #"(?is)<!--.*?-->"#, with: "", options: .regularExpression)
    }

    private static func emojiShortcodes(in text: String) -> String {
        text
            .replacingOccurrences(of: ":tada:", with: "🎉")
            .replacingOccurrences(of: ":smiley:", with: "😃")
            .replacingOccurrences(of: ":warning:", with: "⚠️")
            .replacingOccurrences(of: ":no_entry_sign:", with: "🚫")
            .replacingOccurrences(of: ":white_check_mark:", with: "✅")
            .replacingOccurrences(of: ":x:", with: "❌")
            .replacingOccurrences(of: ":rocket:", with: "🚀")
            .replacingOccurrences(of: ":eyes:", with: "👀")
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

    private static func taskItem(of line: String) -> (checked: Bool, text: String)? {
        for marker in ["- ", "* ", "+ "] where line.hasPrefix(marker) {
            let item = String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
            if item.hasPrefix("[ ] ") {
                return (false, String(item.dropFirst(4)).trimmingCharacters(in: .whitespaces))
            }
            if item.hasPrefix("[x] ") || item.hasPrefix("[X] ") {
                return (true, String(item.dropFirst(4)).trimmingCharacters(in: .whitespaces))
            }
        }
        return nil
    }
}
