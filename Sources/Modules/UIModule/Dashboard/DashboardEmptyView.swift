import Foundation
import SwiftUI

/// Empty dashboard content for the active author filter.
package struct DashboardEmptyView: View {
    /// Filter that produced no dashboard results.
    package let authorFilter: DashboardAuthorFilter

    /// Creates an empty dashboard view.
    package init(authorFilter: DashboardAuthorFilter) {
        self.authorFilter = authorFilter
    }

    /// Empty state content.
    package var body: some View {
        ContentUnavailableView(title, systemImage: "arrow.trianglehead.branch", description: Text(description))
    }

    private var title: String {
        switch authorFilter {
        case .mine:
            "No pull requests opened by you"
        case .askedForReview:
            "No pull requests asking for your review"
        case .all:
            "No open pull requests"
        }
    }

    private var description: String {
        switch authorFilter {
        case .mine:
            "Pull requests you open in this repository will appear here."
        case .askedForReview:
            "Pull requests where your review is requested will appear here."
        case .all:
            "Open pull requests in this repository will appear here."
        }
    }
}
