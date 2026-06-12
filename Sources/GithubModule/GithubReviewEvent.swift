import Foundation

/// The verdict submitted with a review.
package enum GithubReviewEvent: String, Sendable, CaseIterable {
    case approve = "APPROVE"
    case requestChanges = "REQUEST_CHANGES"
    case comment = "COMMENT"
}
