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
        let delegate = WindowDelegate()
        let toolbarDelegate = WindowToolbarDelegate(title: title(for: content))
        let frame = NSRect(origin: .zero, size: size)
        let hostingController = NSHostingController(
            rootView: rootView(for: content)
                .rootView()
        )
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
        window.isReleasedWhenClosed = true
        window.delegate = delegate
        window.contentViewController = hostingController

        app.setActivationPolicy(.regular)
        window.center()
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)

        withExtendedLifetime((window, delegate, toolbarDelegate)) {
            app.run()
        }
    }

    @MainActor
    @ViewBuilder
    private func rootView(for content: WindowContent) -> some View {
        switch content {
        case .dashboard(let pullRequests, let repository):
            DashboardView(pullRequests: pullRequests, repository: repository)
        case .pullRequest(let pullRequest, let repository):
            PullRequestView(pullRequest: pullRequest, repository: repository)
        }
    }

    private func title(for content: WindowContent) -> String {
        switch content {
        case .dashboard(_, let repository):
            repository.fullName
        case .pullRequest(let pullRequest, let repository):
            "\(repository.fullName) #\(pullRequest.number)"
        }
    }
}
