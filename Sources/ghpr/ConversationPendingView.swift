import DiffUIModule
import Foundation
import SwiftUI

/// A pending (unsubmitted) review comment in the conversation timeline:
/// the file and line it targets, the draft body, and a remove button.
struct ConversationPendingView: View {
    let comment: PendingComment
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            MarkdownView(text: comment.body)
                .padding(10)
        }
        .background(.orange.opacity(0.05), in: .rect(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.orange.opacity(0.4), lineWidth: 1))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("\(comment.path):\(lineReference)")
                .font(.caption.monospaced().weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            Label("Pending", systemImage: "clock")
                .font(.caption.weight(.medium))
                .foregroundStyle(.orange)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Remove from review")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private var lineReference: String {
        switch comment.anchor {
        case .old(let line): "L\(line)"
        case .new(let line): "R\(line)"
        }
    }
}
