import AppKit
import Foundation
import SwiftUI

/// Opens the main ghpr SwiftUI window from the CLI process.
package struct WindowRunner {
    private let size: CGSize

    /// Creates a window runner.
    package init(size: CGSize = CGSize(width: 900, height: 600)) {
        self.size = size
    }

    /// Opens a SwiftUI window for the requested content.
    @MainActor
    package func open(_ content: WindowContent) {
        let app = NSApplication.shared
        let windowStore = WindowStore()
        let resources = makeWindow(for: content, windowStore: windowStore, terminatesOnClose: true)

        windowStore.insert(resources)

        app.setActivationPolicy(.regular)
        resources.show()
        app.activate(ignoringOtherApps: true)

        withExtendedLifetime(windowStore) {
            app.run()
        }
    }

    @MainActor
    private func makeWindow(
        for content: WindowContent,
        windowStore: WindowStore,
        terminatesOnClose: Bool
    ) -> WindowResources {
        let delegate = WindowDelegate(terminatesOnClose: terminatesOnClose)
        let dashboardFilterState = dashboardFilterState(for: content)
        let toolbarDelegate = WindowToolbarDelegate(
            title: title(for: content),
            openPullRequestCount: openPullRequestCount(for: content),
            dashboardFilterState: dashboardFilterState
        )
        let frame = NSRect(origin: .zero, size: size)
        let hostingController = NSHostingController(
            rootView: rootView(for: content, dashboardFilterState: dashboardFilterState, windowStore: windowStore)
                .rootView()
        )
        hostingController.sizingOptions = []
        hostingController.view.frame = frame
        hostingController.view.autoresizingMask = [.width, .height]

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = title(for: content)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.toolbar = toolbarDelegate.makeToolbar()
        window.isReleasedWhenClosed = false
        window.delegate = delegate
        window.contentViewController = hostingController

        return WindowResources(window: window, delegate: delegate, toolbarDelegate: toolbarDelegate)
    }

    @MainActor
    @ViewBuilder
    private func rootView(
        for content: WindowContent,
        dashboardFilterState: DashboardFilterState?,
        windowStore: WindowStore
    ) -> some View {
        switch content {
        case .dashboard(let pullRequests, let repository, let currentUser):
            DashboardView(
                pullRequests: pullRequests,
                repository: repository,
                currentUser: currentUser,
                filterState: dashboardFilterState ?? DashboardFilterState(),
                openPullRequest: { pullRequest in
                    let resources = makeWindow(
                        for: .pullRequest(pullRequest, repository),
                        windowStore: windowStore,
                        terminatesOnClose: false
                    )
                    windowStore.insert(resources)
                    resources.show()
                }
            )
        case .pullRequest(let pullRequest, let repository):
            PullRequestView(pullRequest: pullRequest, repository: repository)
        }
    }

    private func title(for content: WindowContent) -> String {
        switch content {
        case .dashboard(_, let repository, _):
            repository.fullName
        case .pullRequest(let pullRequest, let repository):
            "\(repository.fullName) #\(pullRequest.number)"
        }
    }

    @MainActor
    private func dashboardFilterState(for content: WindowContent) -> DashboardFilterState? {
        switch content {
        case .dashboard:
            DashboardFilterState()
        case .pullRequest:
            nil
        }
    }

    private func openPullRequestCount(for content: WindowContent) -> Int? {
        switch content {
        case .dashboard(let pullRequests, _, _):
            pullRequests.count
        case .pullRequest:
            nil
        }
    }
}
