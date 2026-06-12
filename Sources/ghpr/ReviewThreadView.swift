import Foundation
import GithubModule
import SwiftUI

/// One inline review conversation, styled after GitHub's thread card:
/// collapsible header with the line reference, comments with avatars and
/// reactions, a reply field, and a resolve button.
struct ReviewThreadView: View {
    let thread: GithubReviewThread
    let pullRequestAuthor: String?
    var onReply: ((String) -> Void)?
    var onResolve: (() -> Void)?
    var onReact: ((GithubReviewComment, GithubReactionContent) -> Void)?

    @State private var isCollapsed = false
    @State private var replyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if !isCollapsed {
                Divider()
                content
            }
        }
        .background(.background.opacity(0.6), in: .rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator, lineWidth: 1)
        )
        .frame(maxWidth: 640, alignment: .leading)
    }

    // MARK: Header

    private var header: some View {
        Button {
            isCollapsed.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Comment on line \(lineReference)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if isCollapsed {
                    Text("· \(thread.comments.count) comment\(thread.comments.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if thread.isResolved {
                    Label("Resolved", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                }
            }
            .contentShape(.rect)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }

    private var lineReference: String {
        let side = thread.diffSide == "LEFT" ? "L" : "R"
        return thread.line.map { "\(side)\($0)" } ?? "?"
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(thread.comments, id: \.id) { comment in
                ReviewCommentView(
                    comment: comment,
                    isPullRequestAuthor: comment.authorLogin != nil && comment.authorLogin == pullRequestAuthor,
                    onReact: { reaction in onReact?(comment, reaction) }
                )
            }
            if let onReply {
                replyField(onReply)
            }
            if !thread.isResolved, let onResolve {
                Button("Resolve comment", action: onResolve)
                    .controlSize(.small)
            }
        }
        .padding(10)
    }

    private func replyField(_ onReply: @escaping (String) -> Void) -> some View {
        TextField("Write a reply", text: $replyText)
            .textFieldStyle(.roundedBorder)
            .font(.callout)
            .onSubmit {
                let body = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !body.isEmpty else { return }
                onReply(body)
                replyText = ""
            }
    }
}
