import Foundation
import GithubModule
import SwiftUI

/// Pull request summary shown inside a section tab.
package struct PullRequestHeaderView: View {
    /// Pull request summarized by the header.
    package let pullRequest: GithubPullRequest
    /// Repository that owns the pull request.
    package let repository: GithubRepository

    private let spacing = LayoutSpacing()

    /// Creates a pull request header.
    package init(pullRequest: GithubPullRequest, repository: GithubRepository) {
        self.pullRequest = pullRequest
        self.repository = repository
    }

    /// Title, number, state, merge target, and diff summary.
    package var body: some View {
        VStack(alignment: .leading, spacing: spacing.large) {
            titleBlock

            HStack(alignment: .firstTextBaseline, spacing: spacing.medium) {
                stateBadge
                mergeSummary

                Spacer(minLength: spacing.large)

                diffSummary
            }
        }
        .padding(.horizontal, spacing.xlarge)
        .padding(.vertical, spacing.large)
    }

    private var titleBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: spacing.medium) {
            Text("#\(pullRequest.number)")
                .font(.title)
                .foregroundStyle(.secondary)

            Text(pullRequest.title)
                .font(.title)
                .fontWeight(.semibold)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stateBadge: some View {
        Label(pullRequest.state.capitalized, systemImage: stateIconName)
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, spacing.medium)
            .padding(.vertical, spacing.small)
            .background(stateColor, in: .capsule)
    }

    private var mergeSummary: some View {
        HStack(alignment: .firstTextBaseline, spacing: spacing.small) {
            Text(pullRequest.user?.login ?? "unknown")
                .fontWeight(.semibold)
                .underline()

            Text("wants to merge")
            Text(commitSummary)
            Text("into")
            branchText(baseBranchName)
            Text("from")
            branchText(headBranchName)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    @ViewBuilder
    private var diffSummary: some View {
        if let additions = pullRequest.additions, let deletions = pullRequest.deletions {
            HStack(spacing: spacing.small) {
                Text("+\(additions)")
                    .foregroundStyle(.green)

                Text("-\(deletions)")
                    .foregroundStyle(.red)
            }
            .font(.callout)
            .fontWeight(.semibold)
        }
    }

    private func branchText(_ branch: String) -> some View {
        Text(branch)
            .fontDesign(.monospaced)
            .foregroundStyle(.blue)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, spacing.small)
            .padding(.vertical, spacing.xsmall)
            .background(.quaternary, in: .rect(cornerRadius: spacing.small))
    }

    private var commitSummary: String {
        let count = pullRequest.commits ?? 0
        return "\(count) \(count == 1 ? "commit" : "commits")"
    }

    private var baseBranchName: String {
        qualifiedBranchName(ref: pullRequest.base, fallbackRepository: repository.fullName)
    }

    private var headBranchName: String {
        qualifiedBranchName(ref: pullRequest.head, fallbackRepository: nil)
    }

    private func qualifiedBranchName(ref: GithubBranchRef, fallbackRepository: String?) -> String {
        guard let fullName = ref.repo?.fullName ?? fallbackRepository else {
            return ref.ref
        }

        return "\(fullName):\(ref.ref)"
    }

    private var stateIconName: String {
        pullRequest.state == "open" ? "arrow.trianglehead.branch" : "checkmark"
    }

    private var stateColor: Color {
        pullRequest.state == "open" ? .green : .secondary
    }
}
