import Foundation
import GithubModule
import SwiftUI

/// The Conversation tab: the PR's state, author, branches, labels,
/// reviewers, and markdown description.
struct ReviewOverviewView: View {
    let data: ReviewData

    private var pullRequest: GithubPullRequest { data.pullRequest }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if !pullRequest.labels.isEmpty || !pullRequest.requestedReviewers.isEmpty {
                    badges
                }
                Divider()
                description
            }
            .padding(20)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(pullRequest.title) ")
                .font(.title2.weight(.semibold))
            + Text("#\(pullRequest.number)")
                .font(.title2)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                stateBadge
                Text("\(pullRequest.user?.login ?? "ghost") wants to merge")
                    .foregroundStyle(.secondary)
                Text(pullRequest.head.ref)
                    .font(.callout.monospaced())
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(pullRequest.base.ref)
                    .font(.callout.monospaced())
            }
            .font(.callout)
        }
    }

    private var stateBadge: some View {
        Text(stateText)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(stateColor, in: .capsule)
    }

    private var stateText: String {
        if pullRequest.draft { "Draft" }
        else if pullRequest.mergedAt != nil { "Merged" }
        else if pullRequest.state == "open" { "Open" }
        else { "Closed" }
    }

    private var stateColor: Color {
        if pullRequest.draft { .gray }
        else if pullRequest.mergedAt != nil { .purple }
        else if pullRequest.state == "open" { .green }
        else { .red }
    }

    private var badges: some View {
        HStack(spacing: 12) {
            ForEach(pullRequest.labels, id: \.name) { label in
                Text(label.name)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((Color(hex: label.color) ?? .gray).opacity(0.25), in: .capsule)
            }
            if !pullRequest.requestedReviewers.isEmpty {
                Text("Reviewers: \(pullRequest.requestedReviewers.map(\.login).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var description: some View {
        Group {
            if let body = pullRequest.body, !body.isEmpty {
                MarkdownView(text: body)
            } else {
                Text("No description provided.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
