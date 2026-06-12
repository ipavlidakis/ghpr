import Foundation

/// Block-level structure of a markdown document. `AttributedString`'s full
/// markdown parsing produces presentation intents SwiftUI ignores, so block
/// layout (headings, lists, fences) is parsed here and styled natively;
/// inline styling stays with `AttributedString`.
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case code(String)
    case bullets([String])
    case quote(String)
    case rule

    static func parse(_ text: String) -> [MarkdownBlock] {
        // GitHub bodies use CRLF; "\r\n" is a single grapheme in Swift, so
        // splitting on "\n" without normalizing would never split at all.
        let text = text.replacingOccurrences(of: "\r\n", with: "\n")

        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var bullets: [String] = []
        var codeLines: [String] = []
        var inCodeFence = false

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

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

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
