import Foundation
import SwiftUI

/// Open and closed pull request summary for the dashboard toolbar.
package struct DashboardToolbarSummaryView: View {
    /// Number of open pull requests.
    package let openPullRequestCount: Int
    /// Number of closed pull requests.
    package let closedPullRequestCount: Int

    private let spacing = LayoutSpacing()

    /// Creates a dashboard toolbar summary.
    package init(openPullRequestCount: Int, closedPullRequestCount: Int) {
        self.openPullRequestCount = openPullRequestCount
        self.closedPullRequestCount = closedPullRequestCount
    }

    /// Dashboard summary content.
    package var body: some View {
        HStack(spacing: spacing.large) {
            Label("\(openPullRequestCount) Open", systemImage: "arrow.trianglehead.branch")
                .font(.headline)

            Text("\(closedPullRequestCount) Closed")
                .foregroundStyle(.secondary)
        }
    }
}
