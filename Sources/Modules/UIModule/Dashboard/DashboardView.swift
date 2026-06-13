import Foundation
import GithubModule
import SwiftUI

/// Dashboard surface for repository pull requests.
package struct DashboardView: View {
    /// Pull requests shown in the dashboard.
    package let pullRequests: [GithubPullRequest]
    /// Repository that owns the dashboard pull requests.
    package let repository: GithubRepository
    /// User viewing the dashboard.
    package let currentUser: GithubUser
    /// Shared dashboard filter state.
    package let filterState: DashboardFilterState
    /// Opens a pull request from the dashboard.
    package let openPullRequest: @MainActor (GithubPullRequest) async -> Void

    @State private var loadingPullRequestNumbers: Set<Int> = []

    /// Creates a dashboard view for a repository and its pull requests.
    package init(
        pullRequests: [GithubPullRequest],
        repository: GithubRepository,
        currentUser: GithubUser,
        filterState: DashboardFilterState,
        openPullRequest: @escaping @MainActor (GithubPullRequest) async -> Void
    ) {
        self.pullRequests = pullRequests
        self.repository = repository
        self.currentUser = currentUser
        self.filterState = filterState
        self.openPullRequest = openPullRequest
    }

    /// Pull request dashboard content.
    package var body: some View {
        Group {
            if filteredPullRequests.isEmpty {
                DashboardEmptyView(authorFilter: filterState.authorFilter)
            } else {
                DashboardPullRequestTable(
                    pullRequests: filteredPullRequests,
                    loadingPullRequestNumbers: loadingPullRequestNumbers,
                    openPullRequest: open
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredPullRequests: [GithubPullRequest] {
        switch filterState.authorFilter {
        case .mine:
            pullRequests.filter { $0.user?.login == currentUser.login }
        case .askedForReview:
            pullRequests.filter { pullRequest in
                pullRequest.requestedReviewers.contains { $0.login == currentUser.login }
            }
        case .all:
            pullRequests
        }
    }

    private func open(_ pullRequest: GithubPullRequest) {
        guard !loadingPullRequestNumbers.contains(pullRequest.number) else {
            return
        }

        loadingPullRequestNumbers.insert(pullRequest.number)

        Task { @MainActor in
            await openPullRequest(pullRequest)
            loadingPullRequestNumbers.remove(pullRequest.number)
        }
    }
}
