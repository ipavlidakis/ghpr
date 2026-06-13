import Foundation
import GithubModule
import SwiftUI

/// Pull request summary shown at the top of the conversation.
struct ConversationHeaderView: View {
    let pullRequest: GithubPullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleRow
            metadataRow
            if !pullRequest.labels.isEmpty {
                labelsRow
            }
        }
        .padding(14)
        .modifier(ReviewSurface())
    }

    private var titleRow: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(pullRequest.title)
                .font(.title2.weight(.semibold))
                .lineLimit(2)
            Text(verbatim: "#\(pullRequest.number)")
                .font(.title2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var metadataRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                stateBadge
                authorText
                branchFlow
                statsText
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    stateBadge
                    authorText
                    Spacer(minLength: 0)
                    statsText
                }
                branchFlow
            }
        }
        .font(.callout)
    }

    private var authorText: some View {
        Text("\(pullRequest.user?.login ?? "ghost") wants to merge")
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var branchFlow: some View {
        HStack(spacing: 6) {
            branchPill(pullRequest.head.ref)
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            branchPill(pullRequest.base.ref)
        }
        .lineLimit(1)
    }

    private func branchPill(_ text: String) -> some View {
        Text(text)
            .font(.callout.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.background.tertiary, in: .rect(cornerRadius: 5))
    }

    private var statsText: some View {
        HStack(spacing: 6) {
            if let changedFiles = pullRequest.changedFiles {
                Text("\(changedFiles) files")
            }
            if let additions = pullRequest.additions {
                Text("+\(additions)")
                    .foregroundStyle(.green)
            }
            if let deletions = pullRequest.deletions {
                Text("-\(deletions)")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .lineLimit(1)
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

    private var labelsRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(pullRequest.labels, id: \.name) { label in
                    Text(label.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((Color(hex: label.color) ?? .gray).opacity(0.25), in: .capsule)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
