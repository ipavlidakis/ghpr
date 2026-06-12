import Foundation
import GithubModule
import SwiftUI

/// One inline review conversation, with reply and resolve actions.
struct ReviewThreadView: View {
    let thread: GithubReviewThread
    var onReply: ((String) -> Void)?
    var onResolve: (() -> Void)?

    @State private var replyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            comments
            if let onReply {
                replyField(onReply)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            if thread.isResolved {
                Label("Resolved", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
            Spacer()
            if !thread.isResolved, let onResolve {
                Button("Resolve", action: onResolve)
                    .controlSize(.small)
            }
        }
    }

    private var comments: some View {
        ForEach(thread.comments, id: \.id) { comment in
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(comment.authorLogin ?? "ghost")
                        .font(.caption.weight(.semibold))
                    Text(comment.createdAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(AttributedString(githubMarkdown: comment.body))
                    .font(.callout)
                    .textSelection(.enabled)
            }
        }
    }

    private func replyField(_ onReply: @escaping (String) -> Void) -> some View {
        HStack(spacing: 6) {
            TextField("Reply…", text: $replyText)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .onSubmit { submitReply(onReply) }
            Button("Send") {
                submitReply(onReply)
            }
            .controlSize(.small)
            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func submitReply(_ onReply: (String) -> Void) {
        let body = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        onReply(body)
        replyText = ""
    }
}
