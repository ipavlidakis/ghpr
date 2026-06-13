import Foundation
import SwiftUI

/// Renders parsed markdown blocks with native styling. Recursive:
/// `<details>` blocks nest a fresh blocks view inside a disclosure.
struct MarkdownBlocksView: View {
    let blocks: [MarkdownBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(AttributedString(githubMarkdown: text))
                .font(headingFont(level))
                .padding(.top, level <= 2 ? 6 : 3)
        case .paragraph(let text):
            Text(AttributedString(githubMarkdown: text))
                .font(.callout)
                .lineSpacing(3)
        case .rightAlignedParagraph(let text):
            Text(AttributedString(githubMarkdown: text))
                .font(.callout)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .trailing)
        case .code(let language, let code):
            codeView(language: language, code: code)
        case .bullets(let items):
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(AttributedString(githubMarkdown: item))
                            .font(.callout)
                    }
                }
            }
        case .task(let checked, let text):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: checked ? "checkmark.square" : "square")
                    .foregroundStyle(.secondary)
                Text(AttributedString(githubMarkdown: text))
                    .font(.callout)
            }
        case .quote(let text):
            HStack(alignment: .top, spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.tertiary)
                    .frame(width: 3)
                Text(AttributedString(githubMarkdown: text))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        case .alert(let kind, let blocks):
            alertView(kind: kind, blocks: blocks)
        case .rule:
            Divider()
        case .table(let header, let rows):
            tableView(header: header, rows: rows)
        case .details(let summary, let blocks):
            DisclosureGroup {
                MarkdownBlocksView(blocks: blocks)
                    .padding(.top, 8)
                    .padding(.leading, 2)
            } label: {
                Text(AttributedString(githubMarkdown: summary))
                    .font(.callout.weight(.medium))
            }
        }
    }

    private func alertView(kind: String, blocks: [MarkdownBlock]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(alertColor(for: kind))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 12) {
                Label(alertTitle(for: kind), systemImage: alertSymbol(for: kind))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(alertColor(for: kind))

                MarkdownBlocksView(blocks: blocks)
            }
        }
    }

    private func tableView(header: [String], rows: [[String]]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            tableRow(header, isHeader: true)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                tableRow(row, isHeader: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(.rect(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.separator.opacity(0.9), lineWidth: 1)
        }
    }

    private func tableRow(_ cells: [String], isHeader: Bool) -> some View {
        GridRow {
            ForEach(Array(cells.enumerated()), id: \.offset) { column, cell in
                Text(AttributedString(githubMarkdown: cell))
                    .font(isHeader ? .callout.weight(.semibold) : .callout)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(
                        minWidth: column == 0 ? 44 : 96,
                        maxWidth: column == 0 ? 300 : 360,
                        alignment: .leading
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(isHeader ? Color.primary.opacity(0.04) : Color.clear)
                    .overlay {
                        Rectangle()
                            .stroke(.separator.opacity(0.9), lineWidth: 1)
                    }
            }
        }
    }

    @ViewBuilder
    private func codeView(language: String?, code: String) -> some View {
        if language == "diff" || language == "patch" {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(code.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                    Text(verbatim: line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(diffForeground(for: line))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 1)
                        .background(diffBackground(for: line))
                }
            }
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 6))
        } else {
            Text(verbatim: code)
                .font(.system(size: 12, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 6))
        }
    }

    private func diffForeground(for line: String) -> Color {
        if line.hasPrefix("+"), !line.hasPrefix("+++") { return .green }
        if line.hasPrefix("-"), !line.hasPrefix("---") { return .red }
        return .primary
    }

    private func diffBackground(for line: String) -> Color {
        if line.hasPrefix("+"), !line.hasPrefix("+++") { return .green.opacity(0.10) }
        if line.hasPrefix("-"), !line.hasPrefix("---") { return .red.opacity(0.10) }
        return .clear
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .title.weight(.semibold)
        case 2: .title2.weight(.semibold)
        case 3: .title3.weight(.semibold)
        default: .headline
        }
    }

    private func alertTitle(for kind: String) -> String {
        switch kind {
        case "note": "Note"
        case "tip": "Tip"
        case "important": "Important"
        case "warning": "Warning"
        case "caution": "Caution"
        default: kind.capitalized
        }
    }

    private func alertSymbol(for kind: String) -> String {
        switch kind {
        case "tip": "lightbulb"
        case "warning", "caution": "exclamationmark.triangle"
        case "important": "exclamationmark.bubble"
        default: "info.circle"
        }
    }

    private func alertColor(for kind: String) -> Color {
        switch kind {
        case "tip": .green
        case "warning": .orange
        case "caution": .red
        case "important": .purple
        default: .blue
        }
    }
}
