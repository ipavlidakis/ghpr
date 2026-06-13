import Foundation
import GithubModule
import SwiftUI

/// The Conversation tab: PR header and description, the full timeline
/// (comments, reviews with their threads, commits, events), and the
/// metadata sidebar.
struct ConversationView: View {
    let model: ReviewModel

    @State private var revealedHiddenTimelineItems = 0

    private static let leadingTimelineItems = 12
    private static let trailingTimelineItems = 40
    private static let timelineLoadMoreCount = 100

    private var data: ReviewData { model.data }
    private var pullRequest: GithubPullRequest { data.pullRequest }

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            ConversationTimelineTableView(
                rows: timelineRows,
                contentVersion: timelineContentVersion,
                rowAccessibilityLabel: { row in timelineAccessibilityLabel(for: row) },
                rowContent: { row in AnyView(timelineRowContent(row)) }
            )
            .frame(minWidth: 520, idealWidth: 720, maxWidth: 720)

            ScrollView {
                ConversationSidebarView(
                    requestedReviewers: pullRequest.requestedReviewers,
                    reviews: reviews,
                    assignees: pullRequest.assignees ?? [],
                    pullRequestAuthor: pullRequest.user?.login
                )
                .padding(.vertical, 20)
            }
            .frame(width: 280)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: 1060, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviews: [GithubReview] {
        data.timeline.compactMap {
            if case .review(let review) = $0 { review } else { nil }
        }
    }

    private var timelineRows: [ConversationTimelineRow] {
        var rows: [ConversationTimelineRow] = [.header, .description]
        rows += leadingTimelineEntries.map { .item(index: $0.index) }
        if hiddenTimelineCount > 0 {
            rows.append(.hidden(count: hiddenTimelineCount))
        }
        rows += revealedHiddenTimelineEntries.map { .item(index: $0.index) }
        rows += trailingTimelineEntries.map { .item(index: $0.index) }
        if !model.pendingComments.isEmpty {
            rows.append(.pending)
        }
        return rows
    }

    private var timelineContentVersion: Int {
        var hasher = Hasher()
        hasher.combine(pullRequest.title)
        hasher.combine(pullRequest.body ?? "")
        hasher.combine(revealedHiddenTimelineItems)
        hasher.combine(model.pendingComments.map(\.id))
        for item in data.timeline {
            hasher.combine(item.chronologicalDate)
            if case .comment(let comment) = item {
                hasher.combine(comment.databaseId)
                hasher.combine(comment.reactions.reduce(0) { $0 + $1.count })
            }
            if case .review(let review) = item {
                hasher.combine(review.databaseId)
                hasher.combine(review.body)
            }
        }
        for thread in data.threads {
            hasher.combine(thread.id)
            hasher.combine(thread.isResolved)
            hasher.combine(thread.comments.count)
        }
        return hasher.finalize()
    }

    @ViewBuilder
    private func timelineRowContent(_ row: ConversationTimelineRow) -> some View {
        switch row {
        case .header:
            ConversationHeaderView(pullRequest: pullRequest)
                .padding(.top, 20)
                .timelineRowFrame()
        case .description:
            description
                .timelineRowFrame()
        case .item(let index):
            if data.timeline.indices.contains(index) {
                itemView(data.timeline[index])
                    .timelineRowFrame()
            }
        case .hidden(let count):
            HiddenTimelineItemsView(count: count) {
                revealedHiddenTimelineItems += Self.timelineLoadMoreCount
            }
            .timelineRowFrame()
        case .pending:
            pendingReview
                .timelineRowFrame()
        }
    }

    private var leadingTimelineEntries: [(index: Int, item: GithubTimelineItem)] {
        let presentation = timelinePresentation
        return Array(data.timeline[..<presentation.hiddenStart].enumerated()).map { ($0.offset, $0.element) }
    }

    private var revealedHiddenTimelineEntries: [(index: Int, item: GithubTimelineItem)] {
        let presentation = timelinePresentation
        guard presentation.revealedStart < presentation.hiddenEnd else { return [] }
        return (presentation.revealedStart..<presentation.hiddenEnd).map { index in
            (index, data.timeline[index])
        }
    }

    private var trailingTimelineEntries: [(index: Int, item: GithubTimelineItem)] {
        let presentation = timelinePresentation
        guard presentation.hiddenEnd < data.timeline.count else { return [] }
        return (presentation.hiddenEnd..<data.timeline.count).map { index in
            (index, data.timeline[index])
        }
    }

    private var hiddenTimelineCount: Int {
        let presentation = timelinePresentation
        return max(0, presentation.revealedStart - presentation.hiddenStart)
    }

    private var timelinePresentation: TimelinePresentation {
        let total = data.timeline.count
        let minimumVisible = Self.leadingTimelineItems + Self.trailingTimelineItems
        guard total > minimumVisible else {
            return TimelinePresentation(hiddenStart: total, revealedStart: total, hiddenEnd: total)
        }

        let hiddenStart = Self.leadingTimelineItems
        let hiddenEnd = total - Self.trailingTimelineItems
        let hiddenTotal = hiddenEnd - hiddenStart
        let revealed = min(revealedHiddenTimelineItems, hiddenTotal)
        return TimelinePresentation(
            hiddenStart: hiddenStart,
            revealedStart: hiddenEnd - revealed,
            hiddenEnd: hiddenEnd
        )
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

    private func timelineAccessibilityLabel(for row: ConversationTimelineRow) -> String {
        switch row {
        case .header:
            return "Pull request header"
        case .description:
            return "Pull request description"
        case .hidden(let count):
            return "\(count) hidden timeline items"
        case .pending:
            return "\(model.pendingComments.count) pending review comments"
        case .item(let index):
            guard data.timeline.indices.contains(index) else { return "Timeline row" }
            return itemAccessibilityLabel(data.timeline[index])
        }
    }

    private func itemAccessibilityLabel(_ item: GithubTimelineItem) -> String {
        switch item {
        case .comment(let comment):
            "Comment by \(comment.authorLogin ?? "ghost")"
        case .review(let review):
            "Review by \(review.authorLogin ?? "ghost"), \(review.state)"
        case .commit(let commit):
            "Commit \(commit.sha.prefix(7))"
        case .event(let event):
            "Timeline event by \(event.actorLogin ?? "ghost")"
        case .unknown:
            "Unknown timeline item"
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
