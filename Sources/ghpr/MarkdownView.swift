import Foundation
import SwiftUI

/// Renders GitHub-flavored markdown with native block styling: headings,
/// paragraphs, lists, code fences, quotes, rules, tables, and `<details>`
/// disclosures.
struct MarkdownView: View {
    let text: String

    var body: some View {
        MarkdownBlocksView(blocks: MarkdownBlock.parse(text))
    }
}
