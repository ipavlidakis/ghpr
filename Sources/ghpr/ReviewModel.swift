import DiffUIModule
import Foundation
import GithubModule
import Observation

/// The review window's state: loaded data, the pending review batch, and
/// the write-path actions. Views render the model and call its methods;
/// every successful write reloads from the API.
@MainActor
@Observable
final class ReviewModel {
    private(set) var data: ReviewData
    private(set) var pendingComments: [PendingComment] = []
    private(set) var isBusy = false
    var errorMessage: String?

    private let client: GithubClient

    init(data: ReviewData, client: GithubClient) {
        self.data = data
        self.client = client
    }

    // MARK: Pending batch

    func addPendingComment(path: String, anchor: DiffLineAnchor, body: String) {
        pendingComments.append(PendingComment(path: path, anchor: anchor, body: body))
    }

    func removePendingComment(id: PendingComment.ID) {
        pendingComments.removeAll { $0.id == id }
    }

    /// Submits the verdict, summary, and all pending comments as one review.
    func submitReview(event: GithubReviewEvent, body: String) async {
        await perform {
            try await self.client.submitReview(
                in: self.data.reference.repository,
                number: self.data.reference.number,
                event: event,
                body: body.isEmpty ? nil : body,
                comments: self.pendingComments.map(Self.draft)
            )
            self.pendingComments.removeAll()
        }
    }

    // MARK: Immediate actions

    /// Posts one comment right away, outside any batch.
    func addSingleComment(path: String, anchor: DiffLineAnchor, body: String) async {
        await perform {
            try await self.client.addComment(
                in: self.data.reference.repository,
                number: self.data.reference.number,
                commitId: self.data.pullRequest.head.sha,
                comment: Self.draft(path: path, anchor: anchor, body: body)
            )
        }
    }

    func reply(to thread: GithubReviewThread, body: String) async {
        guard let commentId = thread.comments.first?.databaseId else {
            errorMessage = "This thread cannot be replied to."
            return
        }
        await perform {
            try await self.client.replyToComment(
                in: self.data.reference.repository,
                number: self.data.reference.number,
                commentId: commentId,
                body: body
            )
        }
    }

    func resolve(thread: GithubReviewThread) async {
        await perform {
            try await self.client.resolveThread(id: thread.id)
        }
    }

    // MARK: Plumbing

    /// Runs a write, surfaces any error, and refreshes the window on success.
    private func perform(_ write: @escaping () async throws -> Void) async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await write()
            data = try await ReviewData.load(with: client, reference: data.reference)
        } catch {
            errorMessage = "\(error)"
        }
    }

    private static func draft(_ comment: PendingComment) -> GithubDraftReviewComment {
        draft(path: comment.path, anchor: comment.anchor, body: comment.body)
    }

    private static func draft(path: String, anchor: DiffLineAnchor, body: String) -> GithubDraftReviewComment {
        switch anchor {
        case .old(let line):
            GithubDraftReviewComment(path: path, line: line, side: "LEFT", body: body)
        case .new(let line):
            GithubDraftReviewComment(path: path, line: line, side: "RIGHT", body: body)
        }
    }
}
