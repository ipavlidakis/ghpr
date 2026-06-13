import Foundation
import GithubModule
import SwiftUI

/// Pull request review surface.
package struct PullRequestView: View {
    /// Pull request shown by the review surface.
    package let pullRequest: GithubPullRequest
    /// Repository that owns the pull request.
    package let repository: GithubRepository

    /// Creates a pull request view for a repository pull request.
    package init(pullRequest: GithubPullRequest, repository: GithubRepository) {
        self.pullRequest = pullRequest
        self.repository = repository
    }

    /// Blue placeholder pull request content.
    package var body: some View {
        Color.blue
    }
}
