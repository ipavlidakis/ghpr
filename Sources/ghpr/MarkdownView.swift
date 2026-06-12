import Foundation
import SwiftUI

/// Renders GitHub-flavored markdown with native block styling: headings,
/// paragraphs, lists, code fences, quotes, and rules.
struct MarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(MarkdownBlock.parse(text).enumerated()), id: \.offset) { _, block in
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
        }
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
