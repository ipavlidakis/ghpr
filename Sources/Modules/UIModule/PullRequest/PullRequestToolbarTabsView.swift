import Foundation
import SwiftUI

/// Pull request tab selector hosted in the native title toolbar.
package struct PullRequestToolbarTabsView: View {
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

    /// Creates a pull request toolbar tab selector.
    package init(
        tabState: PullRequestTabState,
        conversationCount: Int,
        commitCount: Int,
        checkCount: Int,
        changedFileCount: Int
    ) {
        self.tabState = tabState
        self.conversationCount = conversationCount
        self.commitCount = commitCount
        self.checkCount = checkCount
        self.changedFileCount = changedFileCount
    }

    /// Segmented pull request tab selector.
    package var body: some View {
        @Bindable var tabState = tabState

        Picker("Pull request section", selection: $tabState.selectedTab) {
            Text("\(PullRequestTab.conversations.title) \(conversationCount)")
                .tag(PullRequestTab.conversations)
            Text("\(PullRequestTab.commits.title) \(commitCount)")
                .tag(PullRequestTab.commits)
            Text("\(PullRequestTab.checks.title) \(checkCount)")
                .tag(PullRequestTab.checks)
            Text("\(PullRequestTab.filesChanged.title) \(changedFileCount)")
                .tag(PullRequestTab.filesChanged)
        }
        .pickerStyle(.segmented)
    }
}
