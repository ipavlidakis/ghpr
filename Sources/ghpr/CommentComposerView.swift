import Foundation
import SwiftUI

/// Inline editor for a new comment on a diff line: batch it into the
/// pending review, post it immediately, or cancel.
struct CommentComposerView: View {
    let onAddToReview: (String) -> Void
    let onCommentNow: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $text)
                .font(.callout)
                .frame(minHeight: 60, maxHeight: 140)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background, in: .rect(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.separator, lineWidth: 1)
                )

            HStack(spacing: 8) {
                Button("Add to review") {
                    onAddToReview(trimmed)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmed.isEmpty)

                Button("Comment now") {
                    onCommentNow(trimmed)
                }
                .disabled(trimmed.isEmpty)

                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
            }
            .controlSize(.small)
        }
        .padding(10)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 8))
        .onAppear { isFocused = true }
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
