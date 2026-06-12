import Foundation

/// A submitted review: the verdict and its optional summary text.
package struct GithubReview: Sendable, Equatable {
    /// `approved`, `changes_requested`, `commented`, or `dismissed`.
    package let state: String
    /// `nil` when the author's account no longer exists.
    package let authorLogin: String?
    package let authorAvatarURL: String?
    package let body: String
    package let submittedAt: Date

    package init(
        state: String,
        authorLogin: String?,
        authorAvatarURL: String? = nil,
        body: String = "",
        submittedAt: Date
    ) {
        self.state = state
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.body = body
        self.submittedAt = submittedAt
    }
}
