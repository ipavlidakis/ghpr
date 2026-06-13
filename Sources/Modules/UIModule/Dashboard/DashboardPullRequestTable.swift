import AppKit
import Foundation
import GithubModule
import SwiftUI

/// AppKit-backed pull request table for dashboard-scale lists.
package struct DashboardPullRequestTable: NSViewRepresentable {
    /// Pull requests displayed by the table.
    package let pullRequests: [GithubPullRequest]
    /// Pull request numbers currently loading.
    package let loadingPullRequestNumbers: Set<Int>
    /// Opens a pull request from a table row.
    package let openPullRequest: @MainActor (GithubPullRequest) -> Void

    /// Creates an AppKit table for dashboard pull requests.
    package init(
        pullRequests: [GithubPullRequest],
        loadingPullRequestNumbers: Set<Int>,
        openPullRequest: @escaping @MainActor (GithubPullRequest) -> Void
    ) {
        self.pullRequests = pullRequests
        self.loadingPullRequestNumbers = loadingPullRequestNumbers
        self.openPullRequest = openPullRequest
    }

    /// Creates the table coordinator that owns AppKit delegate state.
    package func makeCoordinator() -> DashboardPullRequestTableCoordinator {
        DashboardPullRequestTableCoordinator(
            pullRequests: pullRequests,
            loadingPullRequestNumbers: loadingPullRequestNumbers,
            openPullRequest: openPullRequest
        )
    }

    /// Creates the AppKit scroll container and table view.
    package func makeNSView(context: Context) -> NSScrollView {
        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.usesAutomaticRowHeights = true
        tableView.selectionHighlightStyle = .regular
        tableView.allowsMultipleSelection = false
        tableView.allowsColumnResizing = false
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.intercellSpacing = .zero
        tableView.backgroundColor = .clear
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.target = context.coordinator
        tableView.doubleAction = #selector(DashboardPullRequestTableCoordinator.openSelectedPullRequest(_:))

        let column = NSTableColumn(identifier: context.coordinator.columnIdentifier)
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = tableView
        column.width = scrollView.contentSize.width

        context.coordinator.tableView = tableView
        return scrollView
    }

    /// Keeps the AppKit table in sync with SwiftUI state.
    package func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.update(
            pullRequests: pullRequests,
            loadingPullRequestNumbers: loadingPullRequestNumbers,
            openPullRequest: openPullRequest
        )

        guard let tableView = scrollView.documentView as? NSTableView else {
            return
        }

        if let column = tableView.tableColumns.first {
            column.width = scrollView.contentSize.width
        }
        tableView.reloadData()
    }
}
