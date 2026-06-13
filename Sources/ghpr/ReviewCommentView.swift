import Foundation
import GithubModule
import SwiftUI

/// One comment inside a thread: avatar, author, role badges, body,
/// existing reactions, and the add-reaction menu.
struct ReviewCommentView: View {
    let comment: GithubReviewComment
    let isPullRequestAuthor: Bool
    let onReact: (GithubReactionContent) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                header
                DeferredMarkdownView(text: comment.body)
                reactionsRow
            }
        }
    }

    private var avatar: some View {
        AsyncImage(url: comment.authorAvatarURL.flatMap(URL.init(string:))) { image in
            image.resizable()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(.tertiary)
        }
        .frame(width: 22, height: 22)
        .clipShape(.circle)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(comment.authorLogin ?? "ghost")
                .font(.callout.weight(.semibold))
            Text(comment.createdAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            if let association = associationLabel {
                roleBadge(association)
            }
            if isPullRequestAuthor {
                roleBadge("Author")
            }
        }
    }

    private var associationLabel: String? {
        guard let association = comment.authorAssociation, association != "NONE" else { return nil }
        return association.capitalized.replacingOccurrences(of: "_", with: " ")
    }

    private func roleBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(.separator, lineWidth: 1))
    }

    private var reactionsRow: some View {
        ReactionBarView(reactions: comment.reactions, onReact: onReact)
    }
}
