import Foundation
import GithubModule
import SwiftUI

/// Row for one pull request in the dashboard list.
package struct DashboardPullRequestRow: View {
    /// Pull request rendered by this row.
    package let pullRequest: GithubPullRequest

    private let spacing = LayoutSpacing()

    /// Creates a pull request row.
    package init(pullRequest: GithubPullRequest) {
        self.pullRequest = pullRequest
    }

    /// Pull request title, metadata, and labels.
    package var body: some View {
        HStack(alignment: .center, spacing: spacing.medium) {
            Image(systemName: "arrow.trianglehead.branch")
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: spacing.small) {
                titleLine
                metadataLine
            }

            Spacer(minLength: spacing.medium)
        }
        .padding(.horizontal, spacing.large)
        .padding(.vertical, spacing.medium)
    }

    private var titleLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: spacing.medium) {
            Text(pullRequest.title)
                .font(.headline)
                .lineLimit(1)

            ForEach(pullRequest.labels, id: \.name) { label in
                Text(label.name)
                    .font(.caption)
                    .padding(.horizontal, spacing.medium)
                    .padding(.vertical, spacing.small)
                    .background(.quaternary, in: .capsule)
            }
        }
    }

    private var metadataLine: some View {
        HStack(spacing: spacing.small) {
            Text("#\(pullRequest.number)")
            Text("opened by")
            Text(pullRequest.user?.login ?? "unknown")
            if pullRequest.draft {
                Text("·")
                Text("Draft")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
