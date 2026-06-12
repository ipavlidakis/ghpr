import Foundation
import GithubModule
import SwiftUI

/// A one-line timeline event: "actor added the X label", assignment,
/// review request, milestone, and state changes — icon, text, time.
struct ConversationEventRowView: View {
    let event: GithubTimelineEvent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(iconColor)
                .frame(width: 18)
            text
                .font(.callout)
            if let label = event.label {
                labelPill(label)
                Text("label")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Text(event.createdAt, format: .relative(presentation: .named))
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.leading, 4)
    }

    private var actor: String { event.actorLogin ?? "ghost" }

    private var text: Text {
        switch event.kind {
        case .labeled:
            Text(actor).bold() + Text(" added the").foregroundStyle(.secondary)
        case .unlabeled:
            Text(actor).bold() + Text(" removed the").foregroundStyle(.secondary)
        case .assigned where event.assigneeLogin == event.actorLogin:
            Text(actor).bold() + Text(" self-assigned this").foregroundStyle(.secondary)
        case .assigned:
            Text(actor).bold() + Text(" assigned ").foregroundStyle(.secondary) + Text(event.assigneeLogin ?? "ghost").bold()
        case .unassigned:
            Text(actor).bold() + Text(" unassigned ").foregroundStyle(.secondary) + Text(event.assigneeLogin ?? "ghost").bold()
        case .reviewRequested:
            Text(actor).bold() + Text(" requested a review from ").foregroundStyle(.secondary) + Text(event.requestedReviewerName ?? "ghost").bold()
        case .reviewRequestRemoved:
            Text(actor).bold() + Text(" removed the review request from ").foregroundStyle(.secondary) + Text(event.requestedReviewerName ?? "ghost").bold()
        case .milestoned:
            Text(actor).bold() + Text(" added this to the ").foregroundStyle(.secondary) + Text(event.milestoneTitle ?? "").bold() + Text(" milestone").foregroundStyle(.secondary)
        case .demilestoned:
            Text(actor).bold() + Text(" removed this from the ").foregroundStyle(.secondary) + Text(event.milestoneTitle ?? "").bold() + Text(" milestone").foregroundStyle(.secondary)
        case .merged:
            Text(actor).bold() + Text(" merged this pull request").foregroundStyle(.secondary)
        case .closed:
            Text(actor).bold() + Text(" closed this").foregroundStyle(.secondary)
        case .reopened:
            Text(actor).bold() + Text(" reopened this").foregroundStyle(.secondary)
        case .renamed:
            Text(actor).bold() + Text(" changed the title ").foregroundStyle(.secondary) + Text(event.renamedFrom ?? "").strikethrough() + Text(" ") + Text(event.renamedTo ?? "").bold()
        case .forcePushed:
            Text(actor).bold() + Text(" force-pushed the branch").foregroundStyle(.secondary)
        case .readyForReview:
            Text(actor).bold() + Text(" marked this pull request as ready for review").foregroundStyle(.secondary)
        case .convertToDraft:
            Text(actor).bold() + Text(" converted this to draft").foregroundStyle(.secondary)
        }
    }

    private func labelPill(_ label: GithubLabel) -> some View {
        Text(label.name)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background((Color(hex: label.color) ?? .gray).opacity(0.25), in: .capsule)
    }

    private var icon: String {
        switch event.kind {
        case .labeled, .unlabeled: "tag"
        case .assigned, .unassigned: "person"
        case .reviewRequested, .reviewRequestRemoved: "eye"
        case .milestoned, .demilestoned: "flag"
        case .merged: "arrow.triangle.merge"
        case .closed: "circle.slash"
        case .reopened: "smallcircle.filled.circle"
        case .renamed: "pencil"
        case .forcePushed: "arrow.up.circle"
        case .readyForReview: "eye.circle"
        case .convertToDraft: "pencil.circle"
        }
    }

    private var iconColor: Color {
        switch event.kind {
        case .merged: .purple
        case .closed: .red
        case .reopened: .green
        default: .secondary
        }
    }
}
