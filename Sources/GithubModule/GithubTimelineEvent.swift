import Foundation

/// A non-comment timeline entry: label, assignment, review request,
/// milestone, branch, and state-change events.
package struct GithubTimelineEvent: Sendable, Equatable {
    package enum Kind: String, Sendable {
        case labeled
        case unlabeled
        case assigned
        case unassigned
        case reviewRequested = "review_requested"
        case reviewRequestRemoved = "review_request_removed"
        case milestoned
        case demilestoned
        case merged
        case closed
        case reopened
        case renamed
        case forcePushed = "head_ref_force_pushed"
        case readyForReview = "ready_for_review"
        case convertToDraft = "convert_to_draft"
    }

    package let kind: Kind
    package let actorLogin: String?
    package let createdAt: Date
    /// The label added or removed.
    package let label: GithubLabel?
    /// The user assigned or unassigned.
    package let assigneeLogin: String?
    /// The user or team a review was requested from.
    package let requestedReviewerName: String?
    package let milestoneTitle: String?
    package let renamedFrom: String?
    package let renamedTo: String?

    package init(
        kind: Kind,
        actorLogin: String?,
        createdAt: Date,
        label: GithubLabel? = nil,
        assigneeLogin: String? = nil,
        requestedReviewerName: String? = nil,
        milestoneTitle: String? = nil,
        renamedFrom: String? = nil,
        renamedTo: String? = nil
    ) {
        self.kind = kind
        self.actorLogin = actorLogin
        self.createdAt = createdAt
        self.label = label
        self.assigneeLogin = assigneeLogin
        self.requestedReviewerName = requestedReviewerName
        self.milestoneTitle = milestoneTitle
        self.renamedFrom = renamedFrom
        self.renamedTo = renamedTo
    }
}
