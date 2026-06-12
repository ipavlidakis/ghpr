import Foundation

/// A submitted review: the verdict and its optional summary text.
package struct GithubReview: Sendable, Equatable {
    /// REST id, matched against comments to nest threads under reviews.
    package let databaseId: Int?
    /// `approved`, `changes_requested`, `commented`, or `dismissed`.
    package let state: String
    /// `nil` when the author's account no longer exists.
    package let authorLogin: String?
    package let authorAvatarURL: String?
    package let body: String
    package let submittedAt: Date

    package init(
        databaseId: Int? = nil,
        state: String,
        authorLogin: String?,
        authorAvatarURL: String? = nil,
        body: String = "",
        submittedAt: Date
    ) {
        self.databaseId = databaseId
        self.state = state
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.body = body
        self.submittedAt = submittedAt
    }
}
