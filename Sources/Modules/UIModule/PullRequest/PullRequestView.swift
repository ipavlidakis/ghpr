import Foundation
import GithubModule
import SwiftUI

/// Pull request review surface.
package struct PullRequestView: View {
    /// Pull request shown by the review surface.
    package let pullRequest: GithubPullRequest
    /// Repository that owns the pull request.
    package let repository: GithubRepository
    /// Number of check runs associated with the pull request.
    package let checkRunCount: Int
    /// Shared tab selection state.
    package let tabState: PullRequestTabState

    /// Creates a pull request view for a repository pull request.
    package init(
        pullRequest: GithubPullRequest,
        repository: GithubRepository,
        checkRunCount: Int,
        tabState: PullRequestTabState
    ) {
        self.pullRequest = pullRequest
        self.repository = repository
        self.checkRunCount = checkRunCount
        self.tabState = tabState
    }

    /// Pull request content split into review sections.
    package var body: some View {
        PullRequestTabsView(
            tabState: tabState,
            conversationCount: conversationCount,
            commitCount: commitCount,
            checkCount: checkRunCount,
            changedFileCount: pullRequest.changedFiles ?? 0
        )
    }

    private var conversationCount: Int {
        (pullRequest.comments ?? 0) + (pullRequest.reviewComments ?? 0)
    }

    private var commitCount: Int {
        pullRequest.commits ?? 0
    }
}
