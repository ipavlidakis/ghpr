import Foundation
import GithubModule
import SwiftUI

/// A review thread in the conversation timeline, GitHub-style: file path
/// header, the diff excerpt the thread hangs on, its comments, a reply
/// field, and the resolve/unresolve bar.
struct ConversationThreadCard: View {
    let thread: GithubReviewThread
    let pullRequestAuthor: String?
    let onReply: (String) -> Void
    let onResolve: () -> Void
    let onUnresolve: () -> Void
    let onReact: (GithubReviewComment, GithubReactionContent) -> Void

    @State private var isExpanded: Bool
    @State private var replyText = ""

    init(
        thread: GithubReviewThread,
        pullRequestAuthor: String?,
        onReply: @escaping (String) -> Void,
        onResolve: @escaping () -> Void,
        onUnresolve: @escaping () -> Void,
        onReact: @escaping (GithubReviewComment, GithubReactionContent) -> Void
    ) {
        self.thread = thread
        self.pullRequestAuthor = pullRequestAuthor
        self.onReply = onReply
        self.onResolve = onResolve
        self.onUnresolve = onUnresolve
        self.onReact = onReact
        _isExpanded = State(initialValue: !thread.isResolved)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded {
                Divider()
                if let hunk = thread.comments.first?.diffHunk, !hunk.isEmpty {
                    DiffExcerptView(hunk: hunk)
                    Divider()
                }
                comments
                Divider()
                resolveBar
            }
        }
        .background(.background.opacity(0.6), in: .rect(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator, lineWidth: 1))
    }

    private var header: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(thread.path)
                    .font(.caption.monospaced().weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !isExpanded {
                    Text("· \(thread.comments.count) comment\(thread.comments.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 8)
                if thread.isOutdated {
                    badge("Outdated", color: .orange)
                }
                if thread.isResolved {
                    badge("Resolved", color: .purple)
                }
            }
            .contentShape(.rect)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1))
    }

    private var comments: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(thread.comments, id: \.id) { comment in
                ReviewCommentView(
                    comment: comment,
                    isPullRequestAuthor: comment.authorLogin != nil && comment.authorLogin == pullRequestAuthor,
                    onReact: { reaction in onReact(comment, reaction) }
                )
            }
            TextField("Reply...", text: $replyText)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .onSubmit {
                    let body = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !body.isEmpty else { return }
                    onReply(body)
                    replyText = ""
                }
        }
        .padding(10)
    }

    private var resolveBar: some View {
        HStack(spacing: 10) {
            if thread.isResolved {
                Button("Unresolve conversation", action: onUnresolve)
                    .controlSize(.small)
                if let resolver = thread.resolvedByLogin {
                    Text("\(resolver) marked this conversation as resolved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("Resolve conversation", action: onResolve)
                    .controlSize(.small)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
    }
}
