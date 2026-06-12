import Foundation
import SwiftUI

/// Markdown rendering for PR descriptions and comments.
extension AttributedString {
    /// Best-effort GitHub markdown: inline styles with whitespace preserved,
    /// falling back to plain text when parsing fails.
    init(githubMarkdown text: String) {
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        self = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}
