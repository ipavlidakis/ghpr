import Foundation
import GithubModule
import SwiftUI

/// A GitHub-style conversation card: author strip on top, markdown body,
/// and reactions. Renders both the PR description and issue comments.
struct ConversationCommentView: View {
    let authorLogin: String?
    let authorAvatarURL: String?
    let authorAssociation: String?
    let date: Date
    let isEdited: Bool
    let text: String
    let reactions: [GithubReaction]
    /// `nil` hides the add-reaction button (e.g. on the description).
    let onReact: ((GithubReactionContent) -> Void)?

    @State private var isReactionPickerShown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            MarkdownView(text: text)
                .padding(12)
            if !reactions.isEmpty || onReact != nil {
                reactionsRow
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
        }
        .modifier(ReviewSurface())
    }

    private var login: String { authorLogin ?? "ghost" }
    private var isBot: Bool { login.hasSuffix("[bot]") }
    private var displayName: String { isBot ? String(login.dropLast(5)) : login }

    private var header: some View {
        HStack(spacing: 6) {
            AvatarView(urlString: authorAvatarURL, size: 22)
            Text(displayName)
                .font(.callout.weight(.semibold))
            if isBot {
                roleBadge("Bot")
            }
            Text("commented")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(date, format: .relative(presentation: .named))
                .font(.callout)
                .foregroundStyle(.secondary)
            if isEdited {
                Text("· edited")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let association = associationLabel {
                roleBadge(association)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .clipShape(.rect(topLeadingRadius: 8, topTrailingRadius: 8))
    }

    private var associationLabel: String? {
        guard let authorAssociation, authorAssociation != "NONE" else { return nil }
        return authorAssociation.capitalized.replacingOccurrences(of: "_", with: " ")
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
        HStack(spacing: 6) {
            ForEach(reactions, id: \.content) { reaction in
                Text("\(reaction.content.emoji) \(reaction.count)")
                    .font(.caption)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(.background.tertiary, in: .capsule)
            }
            if let onReact {
                // A Menu misfires inside hosted cells; a popover is reliable.
                Button {
                    isReactionPickerShown = true
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isReactionPickerShown, arrowEdge: .bottom) {
                    HStack(spacing: 4) {
                        ForEach(GithubReactionContent.allCases, id: \.self) { reaction in
                            Button(reaction.emoji) {
                                isReactionPickerShown = false
                                onReact(reaction)
                            }
                            .buttonStyle(.plain)
                            .font(.title3)
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
}
