import Foundation
import GithubModule
import SwiftUI

/// The Conversation tab: PR header and description, the full timeline
/// (comments, reviews with their threads, commits, events), and the
/// metadata sidebar.
struct ConversationView: View {
    let model: ReviewModel

    private var data: ReviewData { model.data }
    private var pullRequest: GithubPullRequest { data.pullRequest }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 28) {
                timeline
                    .frame(maxWidth: 720, alignment: .leading)
                ConversationSidebarView(
                    requestedReviewers: pullRequest.requestedReviewers,
                    reviews: reviews,
                    assignees: pullRequest.assignees ?? [],
                    pullRequestAuthor: pullRequest.user?.login
                )
            }
            .padding(20)
            .frame(maxWidth: 1060, alignment: .topLeading)
            .frame(maxWidth: .infinity)
        }
    }

    private var reviews: [GithubReview] {
        data.timeline.compactMap {
            if case .review(let review) = $0 { review } else { nil }
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            ConversationHeaderView(pullRequest: pullRequest)
            description
            ForEach(Array(data.timeline.enumerated()), id: \.offset) { _, item in
                itemView(item)
            }
            if !model.pendingComments.isEmpty {
                pendingReview
            }
        }
    }

    /// Drafts batched in the files tab, visible here before submission.
    private var pendingReview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
                Text("Pending review")
                    .font(.callout.weight(.semibold))
                Text("\(model.pendingComments.count) comment\(model.pendingComments.count == 1 ? "" : "s") · submit from the Files changed tab")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(model.pendingComments) { comment in
                ConversationPendingView(comment: comment) {
                    model.removePendingComment(id: comment.id)
                }
                .padding(.leading, 26)
            }
        }
    }

    @ViewBuilder
    private func itemView(_ item: GithubTimelineItem) -> some View {
        switch item {
        case .comment(let comment):
            ConversationCommentView(
                authorLogin: comment.authorLogin,
                authorAvatarURL: comment.authorAvatarURL,
                authorAssociation: comment.authorAssociation,
                date: comment.createdAt,
                isEdited: comment.isEdited,
                text: comment.body,
                reactions: comment.reactions,
                onReact: { reaction in
                    Task { await model.react(toIssueComment: comment, with: reaction) }
                }
            )
        case .review(let review):
            reviewItem(review)
        case .commit(let commit):
            ConversationCommitRowView(commit: commit)
        case .event(let event):
            ConversationEventRowView(event: event)
        case .unknown:
            EmptyView()
        }
    }

    /// A review row followed by the thread cards it created.
    private func reviewItem(_ review: GithubReview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ConversationReviewView(review: review)
            ForEach(threads(of: review), id: \.id) { thread in
                ConversationThreadCard(
                    thread: thread,
                    pullRequestAuthor: pullRequest.user?.login,
                    onReply: { body in Task { await model.reply(to: thread, body: body) } },
                    onResolve: { Task { await model.resolve(thread: thread) } },
                    onUnresolve: { Task { await model.unresolve(thread: thread) } },
                    onReact: { comment, reaction in Task { await model.react(to: comment, with: reaction) } }
                )
                .padding(.leading, 26)
            }
        }
    }

    private func threads(of review: GithubReview) -> [GithubReviewThread] {
        guard let reviewId = review.databaseId else { return [] }
        return data.threads
            .filter { $0.reviewDatabaseId == reviewId }
            .sorted { ($0.comments.first?.createdAt ?? .distantPast) < ($1.comments.first?.createdAt ?? .distantPast) }
    }

    // MARK: Description

    private var description: some View {
        ConversationCommentView(
            authorLogin: pullRequest.user?.login,
            authorAvatarURL: pullRequest.user?.avatarUrl,
            authorAssociation: nil,
            date: pullRequest.createdAt,
            isEdited: false,
            text: pullRequest.body?.isEmpty == false ? pullRequest.body! : "_No description provided._",
            reactions: [],
            onReact: nil
        )
    }
}
