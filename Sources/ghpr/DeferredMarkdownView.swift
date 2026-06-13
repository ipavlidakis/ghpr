import Foundation
import SwiftUI

/// Markdown renderer that avoids parsing huge bot comments until requested.
struct DeferredMarkdownView: View {
    let text: String

    @State private var isExpanded = false

    private static let characterLimit = 6000
    private static let lineLimit = 80

    var body: some View {
        if shouldDefer, !isExpanded {
            VStack(alignment: .leading, spacing: 10) {
                MarkdownView(text: preview)

                Button("Show full comment") {
                    isExpanded = true
                }
                .buttonStyle(.link)
                .font(.callout.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            MarkdownView(text: text)
        }
    }

    private var shouldDefer: Bool {
        text.count > Self.characterLimit || text.components(separatedBy: "\n").count > Self.lineLimit
    }

    private var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1_600 else { return trimmed }
        return String(trimmed.prefix(1_600)) + "\n\n..."
    }
}
