import Foundation
import SwiftUI

/// Renders parsed markdown blocks with native styling. Recursive:
/// `<details>` blocks nest a fresh blocks view inside a disclosure.
struct MarkdownBlocksView: View {
    let blocks: [MarkdownBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                .textSelection(.enabled)
        case .code(let code):
            Text(verbatim: code)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 6))
        case .bullets(let items):
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(AttributedString(githubMarkdown: item))
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                }
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

    private func tableView(header: [String], rows: [[String]]) -> some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 6) {
            GridRow {
                ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                    Text(AttributedString(githubMarkdown: cell))
                        .font(.callout.weight(.semibold))
                }
            }
            Divider()
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        Text(AttributedString(githubMarkdown: cell))
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 6))
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .title.weight(.semibold)
        case 2: .title2.weight(.semibold)
        case 3: .title3.weight(.semibold)
        default: .headline
        }
    }
}
