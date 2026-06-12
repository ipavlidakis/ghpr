import Foundation
import SwiftUI

/// A compact rendering of a review comment's `diffHunk`: the hunk header
/// and the last few lines before the commented one, with line numbers and
/// addition/deletion tints — GitHub's thread-card excerpt.
struct DiffExcerptView: View {
    let hunk: String

    private static let visibleLines = 4

    var body: some View {
        let excerpt = Self.parse(hunk)
        VStack(alignment: .leading, spacing: 0) {
            row(old: "...", new: "...", text: excerpt.header, tint: Color.blue.opacity(0.08), textColor: .secondary)
            ForEach(excerpt.lines) { line in
                row(
                    old: line.oldNumber.map(String.init) ?? "",
                    new: line.newNumber.map(String.init) ?? "",
                    text: line.text,
                    tint: line.tint,
                    textColor: .primary
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(old: String, new: String, text: String, tint: Color?, textColor: Color) -> some View {
        HStack(spacing: 0) {
            Text(old)
                .frame(width: 34, alignment: .trailing)
                .foregroundStyle(.tertiary)
            Text(new)
                .frame(width: 34, alignment: .trailing)
                .foregroundStyle(.tertiary)
            Text(verbatim: text)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .padding(.leading, 10)
            Spacer(minLength: 0)
        }
        .font(.system(size: 11.5, design: .monospaced))
        .padding(.vertical, 2.5)
        .background(tint ?? .clear)
    }

    // MARK: Hunk parsing

    private struct ExcerptLine: Identifiable {
        let id: Int
        let oldNumber: Int?
        let newNumber: Int?
        let text: String
        let tint: Color?
    }

    private static func parse(_ hunk: String) -> (header: String, lines: [ExcerptLine]) {
        var raw = hunk.components(separatedBy: "\n")
        guard !raw.isEmpty else { return ("", []) }
        let header = raw.removeFirst()

        var old = 0
        var new = 0
        if let match = header.firstMatch(of: /@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/) {
            old = Int(match.1) ?? 0
            new = Int(match.2) ?? 0
        }

        var lines: [ExcerptLine] = []
        for (index, line) in raw.enumerated() {
            switch line.first {
            case "+":
                lines.append(ExcerptLine(id: index, oldNumber: nil, newNumber: new, text: line, tint: .green.opacity(0.14)))
                new += 1
            case "-":
                lines.append(ExcerptLine(id: index, oldNumber: old, newNumber: nil, text: line, tint: .red.opacity(0.14)))
                old += 1
            case "\\":
                continue
            default:
                lines.append(ExcerptLine(id: index, oldNumber: old, newNumber: new, text: line, tint: nil))
                old += 1
                new += 1
            }
        }
        return (header, Array(lines.suffix(visibleLines)))
    }
}
