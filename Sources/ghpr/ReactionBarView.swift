import Foundation
import GithubModule
import SwiftUI

/// Reusable GitHub reaction row: existing chips plus the add-reaction picker.
struct ReactionBarView: View {
    let reactions: [GithubReaction]
    let onReact: ((GithubReactionContent) -> Void)?

    @State private var isReactionPickerShown = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(reactions, id: \.content) { reaction in
                if let onReact {
                    Button {
                        onReact(reaction.content)
                    } label: {
                        reactionLabel(reaction)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle \(reaction.content.emoji) reaction")
                    .accessibilityIdentifier("ghpr.reaction.\(reaction.content.rawValue.lowercased())")
                    .accessibilityLabel("Toggle \(reaction.content.emoji) reaction")
                    .accessibilityValue("\(reaction.count)")
                } else {
                    reactionLabel(reaction)
                        .accessibilityLabel("\(reaction.content.emoji) reaction")
                        .accessibilityValue("\(reaction.count)")
                }
            }

            if let onReact {
                Button {
                    isReactionPickerShown = true
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .help("Add reaction")
                .accessibilityIdentifier("ghpr.reaction.add")
                .accessibilityLabel("Add reaction")
                .popover(isPresented: $isReactionPickerShown, arrowEdge: .bottom) {
                    HStack(spacing: 6) {
                        ForEach(GithubReactionContent.allCases, id: \.self) { reaction in
                            Button {
                                isReactionPickerShown = false
                                onReact(reaction)
                            } label: {
                                Text(reaction.emoji)
                                    .font(.title3)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .controlSize(.small)
                            .help("React \(reaction.emoji)")
                        }
                    }
                    .padding(8)
                }
            }
        }
    }

    private func reactionLabel(_ reaction: GithubReaction) -> some View {
        HStack(spacing: 4) {
            Text(reaction.content.emoji)
            if reaction.count > 1 {
                Text("\(reaction.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .padding(.horizontal, 9)
        .frame(height: 30)
        .background(.background.tertiary, in: .capsule)
        .overlay {
            Capsule()
                .stroke(.separator.opacity(0.65), lineWidth: 1)
        }
        .contentShape(.capsule)
    }
}
