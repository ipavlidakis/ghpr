import Foundation
import GithubModule
import SwiftUI

/// Dashboard surface for repository pull requests.
package struct DashboardView: View {
    /// Pull requests shown in the dashboard.
    package let pullRequests: [GithubPullRequest]
    /// Repository that owns the dashboard pull requests.
    package let repository: GithubRepository

    /// Creates a dashboard view for a repository and its pull requests.
    package init(pullRequests: [GithubPullRequest], repository: GithubRepository) {
        self.pullRequests = pullRequests
        self.repository = repository
    }

    /// Red placeholder dashboard content.
    package var body: some View {
        Color.clear
    }
}
