import Foundation
import GithubModule
import SwiftUI

/// One inline review conversation, rendered under the line it anchors to.
struct ReviewThreadView: View {
    let thread: GithubReviewThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if thread.isResolved {
                Label("Resolved", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
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
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator, lineWidth: 1)
        )
    }
}
