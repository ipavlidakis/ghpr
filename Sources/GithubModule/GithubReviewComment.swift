import Foundation

/// A single comment inside a review thread.
package struct GithubReviewComment: Sendable, Equatable {
    /// GraphQL node id, used for mutations.
    package let id: String
    /// REST id, used for reply and reaction endpoints.
    package let databaseId: Int?
    /// `nil` when the author's account no longer exists.
    package let authorLogin: String?
    package let authorAvatarURL: String?
    /// `CONTRIBUTOR`, `MEMBER`, `OWNER`, … — GitHub's author association.
    package let authorAssociation: String?
    package let body: String
    package let createdAt: Date
    package let reactions: [GithubReaction]
    /// The unified diff excerpt the comment was left on.
    package let diffHunk: String?
    /// REST id of the review this comment belongs to, linking threads
    /// to their timeline entry.
    package let reviewDatabaseId: Int?

    package init(
        id: String,
        databaseId: Int?,
        authorLogin: String?,
        authorAvatarURL: String? = nil,
        authorAssociation: String? = nil,
        body: String,
        createdAt: Date,
        reactions: [GithubReaction] = [],
        diffHunk: String? = nil,
        reviewDatabaseId: Int? = nil
    ) {
        self.id = id
        self.databaseId = databaseId
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.authorAssociation = authorAssociation
        self.body = body
        self.createdAt = createdAt
        self.reactions = reactions
        self.diffHunk = diffHunk
        self.reviewDatabaseId = reviewDatabaseId
    }
}
