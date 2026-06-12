import Foundation

/// A single comment inside a review thread.
package struct GithubReviewComment: Sendable, Equatable {
    /// GraphQL node id, used for mutations.
    package let id: String
    /// REST id, used for reply endpoints.
    package let databaseId: Int?
    /// `nil` when the author's account no longer exists.
    package let authorLogin: String?
    package let body: String
    package let createdAt: Date

    package init(id: String, databaseId: Int?, authorLogin: String?, body: String, createdAt: Date) {
        self.id = id
        self.databaseId = databaseId
        self.authorLogin = authorLogin
        self.body = body
        self.createdAt = createdAt
    }
}
