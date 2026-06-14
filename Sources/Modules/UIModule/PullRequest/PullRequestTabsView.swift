import Foundation
import GithubModule
import SwiftUI

/// Pull request section tabs.
package struct PullRequestTabsView: View {
    /// Pull request shown inside each section.
    package let pullRequest: GithubPullRequest
    /// Repository that owns the pull request.
    package let repository: GithubRepository
    /// Shared tab selection state.
    package let tabState: PullRequestTabState
    /// Conversation comment count.
    package let conversationCount: Int
    /// Commit count.
    package let commitCount: Int
    /// Check run count.
    package let checkCount: Int
    /// Changed file count.
    package let changedFileCount: Int

    /// Creates a pull request tab selector.
    package init(
        pullRequest: GithubPullRequest,
        repository: GithubRepository,
        tabState: PullRequestTabState,
        conversationCount: Int,
        commitCount: Int,
        checkCount: Int,
        changedFileCount: Int
    ) {
        self.pullRequest = pullRequest
        self.repository = repository
        self.tabState = tabState
        self.conversationCount = conversationCount
        self.commitCount = commitCount
        self.checkCount = checkCount
        self.changedFileCount = changedFileCount
    }

    /// Pull request section tab view.
    package var body: some View {
        @Bindable var tabState = tabState

        TabView(selection: $tabState.selectedTab) {
            ForEach(PullRequestTab.allCases) { tab in
                Tab(value: tab) {
                    content(for: tab)
                } label: {
                    Text(label(for: tab))
                }
            }
        }
    }

    private func content(for tab: PullRequestTab) -> some View {
        VStack(spacing: .zero) {
            PullRequestHeaderView(pullRequest: pullRequest, repository: repository)
            tabContent(for: tab)
        }
    }

    @ViewBuilder
    private func tabContent(for tab: PullRequestTab) -> some View {
        switch tab {
        case .conversations:
            PullRequestConversationsView()
        case .commits:
            PullRequestCommitsView()
        case .checks:
            PullRequestChecksView()
        case .filesChanged:
            PullRequestFilesChangedView()
        }
    }

    private func label(for tab: PullRequestTab) -> String {
        switch tab {
        case .conversations:
            label(title: tab.title, count: conversationCount)
        case .commits:
            label(title: tab.title, count: commitCount)
        case .checks:
            label(title: tab.title, count: checkCount)
        case .filesChanged:
            label(title: tab.title, count: changedFileCount)
        }
    }

    private func label(title: String, count: Int) -> String {
        guard count > 0 else {
            return title
        }

        return "\(title) · \(count)"
    }
}
