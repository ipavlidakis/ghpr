import Foundation
import GithubModule

/// Content routed into the main ghpr SwiftUI window.
package enum WindowContent: Sendable, Equatable {
    /// Repository dashboard content with open pull requests.
    case dashboard([GithubPullRequest], GithubRepository, GithubUser)
    /// Pull request review content for a single repository pull request.
    case pullRequest(GithubPullRequest, GithubRepository, Int)
}
