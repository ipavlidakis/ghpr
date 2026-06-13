import AppKit
import Foundation
import GithubModule
import SwiftUI

/// Delegate and data source for the dashboard pull request table.
@MainActor
package final class DashboardPullRequestTableCoordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    /// Column identifier used by the single-column pull request table.
    package let columnIdentifier = NSUserInterfaceItemIdentifier("pullRequest")

    /// Table view owned by the SwiftUI representable.
    package weak var tableView: NSTableView?

    private let cellIdentifier = NSUserInterfaceItemIdentifier("pullRequestCell")
    private var pullRequests: [GithubPullRequest]
    private var loadingPullRequestNumbers: Set<Int>
    private var openPullRequest: @MainActor (GithubPullRequest) -> Void

    /// Creates table delegate state.
    package init(
        pullRequests: [GithubPullRequest],
        loadingPullRequestNumbers: Set<Int>,
        openPullRequest: @escaping @MainActor (GithubPullRequest) -> Void
    ) {
        self.pullRequests = pullRequests
        self.loadingPullRequestNumbers = loadingPullRequestNumbers
        self.openPullRequest = openPullRequest
    }

    /// Updates the table data source.
    package func update(
        pullRequests: [GithubPullRequest],
        loadingPullRequestNumbers: Set<Int>,
        openPullRequest: @escaping @MainActor (GithubPullRequest) -> Void
    ) {
        self.pullRequests = pullRequests
        self.loadingPullRequestNumbers = loadingPullRequestNumbers
        self.openPullRequest = openPullRequest
    }

    /// Returns the current number of table rows.
    package func numberOfRows(in tableView: NSTableView) -> Int {
        pullRequests.count
    }

    /// Creates or reuses a SwiftUI-hosting table cell.
    package func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard pullRequests.indices.contains(row) else {
            return nil
        }

        let pullRequest = pullRequests[row]
        let rowView = DashboardPullRequestRow(
            pullRequest: pullRequest,
            isLoading: loadingPullRequestNumbers.contains(pullRequest.number)
        )

        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? DashboardPullRequestCellView {
            cell.update(rowView: rowView)
            return cell
        }

        let cell = DashboardPullRequestCellView(rowView: rowView)
        cell.identifier = cellIdentifier
        return cell
    }

    /// Opens the row that was double-clicked.
    @objc
    package func openSelectedPullRequest(_ sender: NSTableView) {
        let row = sender.clickedRow >= 0 ? sender.clickedRow : sender.selectedRow

        guard pullRequests.indices.contains(row) else {
            return
        }

        openPullRequest(pullRequests[row])
    }
}
