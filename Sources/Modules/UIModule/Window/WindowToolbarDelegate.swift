import AppKit
import Foundation
import SwiftUI

/// Builds the native window toolbar used as the title bar surface.
final class WindowToolbarDelegate: NSObject, NSToolbarDelegate {
    private let title: String
    private let openPullRequestCount: Int?
    private let dashboardFilterState: DashboardFilterState?
    private let pullRequestNumber: Int?
    private let pullRequestConversationCount: Int?
    private let pullRequestCommitCount: Int?
    private let pullRequestCheckCount: Int?
    private let pullRequestChangedFileCount: Int?
    private let pullRequestTabState: PullRequestTabState?
    private let titleIdentifier = NSToolbarItem.Identifier("window.title")
    private let dashboardSummaryIdentifier = NSToolbarItem.Identifier("dashboard.summary")
    private let dashboardAuthorFilterIdentifier = NSToolbarItem.Identifier("dashboard.authorFilter")
    private let pullRequestNumberIdentifier = NSToolbarItem.Identifier("pullRequest.number")
    private let pullRequestTabsIdentifier = NSToolbarItem.Identifier("pullRequest.tabs")

    /// Creates a toolbar delegate for a window title.
    init(
        title: String,
        openPullRequestCount: Int? = nil,
        dashboardFilterState: DashboardFilterState? = nil,
        pullRequestNumber: Int? = nil,
        pullRequestConversationCount: Int? = nil,
        pullRequestCommitCount: Int? = nil,
        pullRequestCheckCount: Int? = nil,
        pullRequestChangedFileCount: Int? = nil,
        pullRequestTabState: PullRequestTabState? = nil
    ) {
        self.title = title
        self.openPullRequestCount = openPullRequestCount
        self.dashboardFilterState = dashboardFilterState
        self.pullRequestNumber = pullRequestNumber
        self.pullRequestConversationCount = pullRequestConversationCount
        self.pullRequestCommitCount = pullRequestCommitCount
        self.pullRequestCheckCount = pullRequestCheckCount
        self.pullRequestChangedFileCount = pullRequestChangedFileCount
        self.pullRequestTabState = pullRequestTabState
    }

    /// Creates the toolbar that hosts the window title.
    @MainActor
    func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "window.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .default
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        return toolbar
    }

    @MainActor
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if pullRequestNumber != nil {
            return [pullRequestNumberIdentifier, pullRequestTabsIdentifier, .flexibleSpace]
        }

        var identifiers = [titleIdentifier]

        if openPullRequestCount != nil {
            identifiers.append(dashboardSummaryIdentifier)
        }

        identifiers.append(.flexibleSpace)

        if dashboardFilterState != nil {
            identifiers.append(dashboardAuthorFilterIdentifier)
        }

        return identifiers
    }

    @MainActor
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            titleIdentifier,
            dashboardSummaryIdentifier,
            dashboardAuthorFilterIdentifier,
            pullRequestNumberIdentifier,
            pullRequestTabsIdentifier,
            .flexibleSpace,
        ]
    }

    @MainActor
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case titleIdentifier:
            return titleItem(itemIdentifier: itemIdentifier)
        case dashboardSummaryIdentifier:
            return dashboardSummaryItem(itemIdentifier: itemIdentifier)
        case dashboardAuthorFilterIdentifier:
            return dashboardAuthorFilterItem(itemIdentifier: itemIdentifier)
        case pullRequestNumberIdentifier:
            return pullRequestNumberItem(itemIdentifier: itemIdentifier)
        case pullRequestTabsIdentifier:
            return pullRequestTabsItem(itemIdentifier: itemIdentifier)
        default:
            return nil
        }
    }

    @MainActor
    private func titleItem(itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem {
        let titleView = NSHostingView(rootView: WindowTitleView(title: title))

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = titleView
        item.isBordered = false
        item.style = .plain
        return item
    }

    @MainActor
    private func dashboardSummaryItem(itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        guard let openPullRequestCount else {
            return nil
        }

        let summaryView = NSHostingView(
            rootView: DashboardToolbarSummaryView(
                openPullRequestCount: openPullRequestCount,
                closedPullRequestCount: 0
            )
        )

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = summaryView
        item.isBordered = false
        item.style = .plain
        return item
    }

    @MainActor
    private func dashboardAuthorFilterItem(itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        guard let dashboardFilterState else {
            return nil
        }

        let authorFilterView = NSHostingView(rootView: DashboardAuthorFilterMenu(filterState: dashboardFilterState))

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = authorFilterView
        item.isBordered = false
        item.style = .plain
        return item
    }

    @MainActor
    private func pullRequestNumberItem(itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        guard let pullRequestNumber else {
            return nil
        }

        let numberView = NSHostingView(rootView: PullRequestNumberView(number: pullRequestNumber))

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = numberView
        item.isBordered = false
        item.style = .plain
        return item
    }

    @MainActor
    private func pullRequestTabsItem(itemIdentifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
        guard let pullRequestTabState else {
            return nil
        }

        let tabsView = NSHostingView(
            rootView: PullRequestToolbarTabsView(
                tabState: pullRequestTabState,
                conversationCount: pullRequestConversationCount ?? 0,
                commitCount: pullRequestCommitCount ?? 0,
                checkCount: pullRequestCheckCount ?? 0,
                changedFileCount: pullRequestChangedFileCount ?? 0
            )
        )

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = tabsView
        item.isBordered = false
        item.style = .plain
        return item
    }
}
