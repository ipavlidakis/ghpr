import SwiftUI

extension AttributedString {
    /// Builds line text with the changed ranges tinted.
    ///
    /// `emphasis` ranges must index into `text` — they come from
    /// `IntralineDiff` computed against that exact string.
    init(diffText text: String, emphasis: [Range<String.Index>], tint: Color) {
        self.init()
        var cursor = text.startIndex
        for range in emphasis {
            if cursor < range.lowerBound {
                self += AttributedString(text[cursor..<range.lowerBound])
            }
            var emphasized = AttributedString(text[range])
            emphasized.backgroundColor = tint
            self += emphasized
            cursor = range.upperBound
        }
        if cursor < text.endIndex {
            self += AttributedString(text[cursor...])
        }
    }
}
