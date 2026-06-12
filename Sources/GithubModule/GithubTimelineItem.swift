import Foundation

/// One entry of the PR conversation timeline, decoded from the REST
/// timeline endpoint's heterogeneous payloads. Entries ghpr does not
/// render decode as `.unknown` and are filtered out by the client.
package enum GithubTimelineItem: Sendable, Equatable, Decodable {
    case comment(GithubIssueComment)
    case review(GithubReview)
    case commit(GithubTimelineCommit)
    case event(GithubTimelineEvent)
    case unknown

    package init(from decoder: any Decoder) throws {
        guard let raw = try? Raw(from: decoder) else {
            self = .unknown
            return
        }
        self = raw.item
    }

    /// Every field any supported payload may carry, all optional.
    private struct Raw: Decodable {
        struct Actor: Decodable {
            let login: String
            let avatarUrl: String?
        }
        struct Team: Decodable { let name: String }
        struct Milestone: Decodable { let title: String }
        struct Rename: Decodable {
            let from: String
            let to: String
        }
        struct CommitAuthor: Decodable {
            let name: String?
            let date: Date?
        }

        let event: String?
        let id: Int?
        let actor: Actor?
        let user: Actor?
        let assignee: Actor?
        let requestedReviewer: Actor?
        let requestedTeam: Team?
        let label: GithubLabel?
        let milestone: Milestone?
        let rename: Rename?
        let body: String?
        let state: String?
        let authorAssociation: String?
        let createdAt: Date?
        let updatedAt: Date?
        let submittedAt: Date?
        let reactions: GithubReactionRollup?
        let sha: String?
        let message: String?
        let author: CommitAuthor?

        var item: GithubTimelineItem {
            switch event {
            case "commented":
                guard let id, let body, let createdAt else { return .unknown }
                let author = user ?? actor
                return .comment(GithubIssueComment(
                    databaseId: id,
                    authorLogin: author?.login,
                    authorAvatarURL: author?.avatarUrl,
                    authorAssociation: authorAssociation,
                    body: body,
                    createdAt: createdAt,
                    isEdited: updatedAt.map { $0.timeIntervalSince(createdAt) > 5 } ?? false,
                    reactions: reactions?.reactions ?? []
                ))
            case "reviewed":
                guard let state, let submittedAt else { return .unknown }
                return .review(GithubReview(
                    databaseId: id,
                    state: state.lowercased(),
                    authorLogin: user?.login,
                    authorAvatarURL: user?.avatarUrl,
                    body: body ?? "",
                    submittedAt: submittedAt
                ))
            case "committed":
                guard let sha, let message else { return .unknown }
                return .commit(GithubTimelineCommit(
                    sha: sha,
                    message: message,
                    authorName: author?.name,
                    date: author?.date
                ))
            default:
                guard
                    let kind = event.flatMap(GithubTimelineEvent.Kind.init(rawValue:)),
                    let createdAt
                else { return .unknown }
                return .event(GithubTimelineEvent(
                    kind: kind,
                    actorLogin: actor?.login,
                    createdAt: createdAt,
                    label: label,
                    assigneeLogin: assignee?.login,
                    requestedReviewerName: requestedReviewer?.login ?? requestedTeam?.name,
                    milestoneTitle: milestone?.title,
                    renamedFrom: rename?.from,
                    renamedTo: rename?.to
                ))
            }
        }
    }
}
