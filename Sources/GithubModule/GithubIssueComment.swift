import Foundation

/// A top-level conversation comment on a pull request.
package struct GithubIssueComment: Sendable, Equatable {
    /// REST id, used for the reaction endpoint.
    package let databaseId: Int
    /// `nil` when the author's account no longer exists.
    package let authorLogin: String?
    package let authorAvatarURL: String?
    /// `CONTRIBUTOR`, `MEMBER`, `OWNER`, … — GitHub's author association.
    package let authorAssociation: String?
    package let body: String
    package let createdAt: Date
    package let isEdited: Bool
    package let reactions: [GithubReaction]

    package init(
        databaseId: Int,
        authorLogin: String?,
        authorAvatarURL: String? = nil,
        authorAssociation: String? = nil,
        body: String,
        createdAt: Date,
        isEdited: Bool = false,
        reactions: [GithubReaction] = []
    ) {
        self.databaseId = databaseId
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.authorAssociation = authorAssociation
        self.body = body
        self.createdAt = createdAt
        self.isEdited = isEdited
        self.reactions = reactions
    }
}
