import Foundation
import Observation

/// Main-actor state for the active pull request tab.
@MainActor
@Observable
package final class PullRequestTabState {
    /// Current pull request tab.
    package var selectedTab: PullRequestTab

    /// Creates pull request tab state.
    package init(selectedTab: PullRequestTab = .conversations) {
        self.selectedTab = selectedTab
    }
}
