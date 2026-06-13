import Foundation
import GithubModule
import SwiftUI

/// Pull request review surface.
package struct PullRequestView: View {
    /// Pull request shown by the review surface.
    package let pullRequest: GithubPullRequest
    /// Repository that owns the pull request.
    package let repository: GithubRepository
    /// Shared tab selection state.
    package let tabState: PullRequestTabState

    /// Creates a pull request view for a repository pull request.
    package init(pullRequest: GithubPullRequest, repository: GithubRepository, tabState: PullRequestTabState) {
        self.pullRequest = pullRequest
        self.repository = repository
        self.tabState = tabState
    }

    /// Blue placeholder pull request content.
    package var body: some View {
        switch tabState.selectedTab {
        case .conversations, .commits, .checks, .filesChanged:
            Color.blue
        }
    }
}
