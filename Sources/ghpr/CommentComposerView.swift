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
        HStack(alignment: .top, spacing: 0) {
            content
                .frame(maxWidth: 640, alignment: .leading)
            Spacer(minLength: 0)
        }
        .onAppear { isFocused = true }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("New line comment", systemImage: "text.bubble")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            editor

            HStack(spacing: 8) {
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()

                Button("Comment now") {
                    onCommentNow(trimmed)
                }
                .buttonStyle(.glass)
                .disabled(trimmed.isEmpty)

                Button("Add to review") {
                    onAddToReview(trimmed)
                }
                .buttonStyle(.glassProminent)
                .disabled(trimmed.isEmpty)
            }
            .controlSize(.small)
        }
        .padding(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 8))
    }

    private var editor: some View {
        TextEditor(text: $text)
            .font(.callout)
            .frame(minHeight: 72, maxHeight: 150)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .padding(6)
            .modifier(ReviewSurface(cornerRadius: 6))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Leave a comment")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 12)
                        .padding(.leading, 10)
                        .allowsHitTesting(false)
                }
            }
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
