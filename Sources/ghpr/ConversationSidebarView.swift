import Foundation
import GithubModule
import SwiftUI

/// The conversation tab's metadata column: reviewers with their review
/// state, and assignees.
struct ConversationSidebarView: View {
    let requestedReviewers: [GithubUser]
    let reviews: [GithubReview]
    let assignees: [GithubUser]
    /// Excluded from the reviewers list — own comments are not reviews.
    let pullRequestAuthor: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            section("Reviewers") {
                if reviewers.isEmpty {
                    emptyText("No reviews")
                } else {
                    ForEach(reviewers, id: \.login) { reviewer in
                        HStack(spacing: 6) {
                            AvatarView(urlString: reviewer.avatarURL, size: 20)
                            Text(displayName(reviewer.login))
                                .font(.callout)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Image(systemName: reviewer.icon)
                                .font(.caption)
                                .foregroundStyle(reviewer.color)
                        }
                    }
                }
            }
            Divider()
            section("Assignees") {
                if assignees.isEmpty {
                    emptyText("No one assigned")
                } else {
                    ForEach(assignees, id: \.login) { assignee in
                        HStack(spacing: 6) {
                            AvatarView(urlString: assignee.avatarUrl, size: 20)
                            Text(displayName(assignee.login))
                                .font(.callout)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .frame(width: 200, alignment: .leading)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.tertiary)
    }

    private func displayName(_ login: String) -> String {
        login.hasSuffix("[bot]") ? String(login.dropLast(5)) : login
    }

    // MARK: Reviewer states

    private struct Reviewer {
        let login: String
        let avatarURL: String?
        let icon: String
        let color: Color
    }

    /// Pending requests first, then everyone who reviewed with their
    /// effective state: approval and changes-requested verdicts stick,
    /// comment-only reviews do not override them.
    private var reviewers: [Reviewer] {
        var rows = requestedReviewers.map {
            Reviewer(login: $0.login, avatarURL: $0.avatarUrl, icon: "clock", color: .orange)
        }
        let excluded = Set(requestedReviewers.map(\.login) + [pullRequestAuthor].compactMap(\.self))

        var order: [String] = []
        var states: [String: String] = [:]
        var avatars: [String: String] = [:]
        for review in reviews {
            guard let login = review.authorLogin, !excluded.contains(login) else { continue }
            if !order.contains(login) {
                order.append(login)
            }
            if let avatar = review.authorAvatarURL {
                avatars[login] = avatar
            }
            switch review.state {
            case "approved", "changes_requested":
                states[login] = review.state
            case "dismissed":
                states[login] = "commented"
            default:
                if states[login] == nil {
                    states[login] = "commented"
                }
            }
        }

        rows += order.map { login in
            switch states[login] {
            case "approved":
                Reviewer(login: login, avatarURL: avatars[login], icon: "checkmark", color: .green)
            case "changes_requested":
                Reviewer(login: login, avatarURL: avatars[login], icon: "plusminus", color: .red)
            default:
                Reviewer(login: login, avatarURL: avatars[login], icon: "text.bubble", color: .secondary)
            }
        }
        return rows
    }
}
