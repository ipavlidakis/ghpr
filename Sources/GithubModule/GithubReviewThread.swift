import Foundation

/// An inline review conversation, including its resolution state.
///
/// Sourced from GraphQL because the REST API does not expose thread resolution.
package struct GithubReviewThread: Sendable, Equatable {
    /// GraphQL node id, used for the resolve mutation.
    package let id: String
    package let isResolved: Bool
    package let isOutdated: Bool
    package let path: String
    /// `nil` for outdated threads that no longer map to the current diff.
    package let line: Int?
    package let startLine: Int?
    /// `LEFT` or `RIGHT`.
    package let diffSide: String?
    package let comments: [GithubReviewComment]

    package init(
        id: String,
        isResolved: Bool,
        isOutdated: Bool,
        path: String,
        line: Int?,
        startLine: Int?,
        diffSide: String?,
        comments: [GithubReviewComment]
    ) {
        self.id = id
        self.isResolved = isResolved
        self.isOutdated = isOutdated
        self.path = path
        self.line = line
        self.startLine = startLine
        self.diffSide = diffSide
        self.comments = comments
    }
}
