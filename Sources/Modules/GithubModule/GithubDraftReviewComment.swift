import Foundation

/// One pending inline comment, batched into a review on submit.
package struct GithubDraftReviewComment: Sendable, Equatable, Encodable {
    package let path: String
    package let line: Int
    /// `LEFT` (old side) or `RIGHT` (new side).
    package let side: String
    package let body: String

    package init(path: String, line: Int, side: String, body: String) {
        self.path = path
        self.line = line
        self.side = side
        self.body = body
    }
}
