import Foundation

/// A pull request, as returned by both the list and detail REST endpoints.
///
/// `additions`, `deletions`, and `changedFiles` only exist in detail responses,
/// so they are optional.
package struct GithubPullRequest: Sendable, Equatable, Decodable {
    package let number: Int
    package let title: String
    package let body: String?
    package let state: String
    package let draft: Bool
    package let htmlUrl: String
    /// `nil` when the author's account no longer exists.
    package let user: GithubUser?
    package let labels: [GithubLabel]
    package let requestedReviewers: [GithubUser]
    package let assignees: [GithubUser]?
    package let comments: Int?
    package let reviewComments: Int?
    package let commits: Int?
    package let head: GithubBranchRef
    package let base: GithubBranchRef
    package let createdAt: Date
    package let updatedAt: Date
    package let mergedAt: Date?
    package let additions: Int?
    package let deletions: Int?
    package let changedFiles: Int?
}
