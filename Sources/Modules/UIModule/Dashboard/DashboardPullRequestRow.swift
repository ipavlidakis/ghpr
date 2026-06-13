import Foundation
import GithubModule
import SwiftUI

/// Row for one pull request in the dashboard list.
package struct DashboardPullRequestRow: View {
    /// Pull request rendered by this row.
    package let pullRequest: GithubPullRequest
    /// Whether the row is currently loading a pull request window.
    package let isLoading: Bool

    private let spacing = LayoutSpacing()

    /// Creates a pull request row.
    package init(pullRequest: GithubPullRequest, isLoading: Bool) {
        self.pullRequest = pullRequest
        self.isLoading = isLoading
    }

    /// Pull request title, metadata, and labels.
    package var body: some View {
        HStack(alignment: .center, spacing: spacing.medium) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "arrow.trianglehead.branch")
                    .foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: spacing.small) {
                titleLine
                metadataLine
            }
            .frame(minWidth: .zero, maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, spacing.large)
        .padding(.vertical, spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var titleLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: spacing.medium) {
            Text(pullRequest.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)

            ForEach(pullRequest.labels, id: \.name) { label in
                Text(label.name)
                    .font(.caption)
                    .padding(.horizontal, spacing.medium)
                    .padding(.vertical, spacing.small)
                    .background(.quaternary, in: .capsule)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
