import AppKit
import Foundation
import SwiftUI

/// Boots an unbundled AppKit app around SwiftUI content, straight from the
/// CLI process: activation policy, minimal main menu, window, run loop.
/// `run` blocks until the last window closes, then the process exits and
/// the terminal gets its prompt back.
@MainActor
enum AppBootstrap {
    private static let delegate = AppDelegate()
    private static let frameGuard = WindowFrameGuard()
    private static var cascadeOffset: CGFloat = 0

    /// Boots the app with its first window and blocks in the run loop.
    static func run(title: String, size: NSSize = NSSize(width: 1280, height: 840), content: some View) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        app.mainMenu = mainMenu()

        openWindow(title: title, size: size, content: content)

        app.activate(ignoringOtherApps: true)
        app.run()
    }

    /// Opens an additional window in the running app (dash → review).
    /// The process keeps running until every window is closed.
    static func openWindow(title: String, size: NSSize = NSSize(width: 1280, height: 840), content: some View) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: content)
        hostingView.sizingOptions = []

        // Sandbox the hosting view inside a plain container pinned at
        // sub-required priority: SwiftUI's internal sizing constraints then
        // break against the container instead of resizing the window
        // (otherwise NavigationSplitView collapses the frame to ~120pt).
        let container = NSView()
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostingView)
        let edges = [
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ]
        for constraint in edges {
            constraint.priority = NSLayoutConstraint.Priority(999)
        }
        NSLayoutConstraint.activate(edges)

        window.contentView = container
        window.minSize = NSSize(width: 700, height: 460)
        window.makeKeyAndOrderFront(nil)

        let frame = centeredFrame(size: size).offsetBy(dx: cascadeOffset, dy: -cascadeOffset)
        cascadeOffset = (cascadeOffset + 26).truncatingRemainder(dividingBy: 130)
        window.setFrame(frame, display: true)
        frameGuard.protect(window, frame: frame, for: .seconds(3))
    }

    private static func centeredFrame(size: NSSize) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(origin: .zero, size: size)
        }
        let visible = screen.visibleFrame
        return NSRect(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    /// Just enough menu for a usable window: quit, close, and the edit
    /// actions text fields expect.
    private static func mainMenu() -> NSMenu {
        let menu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit ghpr", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(submenu: appMenu)

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(submenu: editMenu)

        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        menu.addItem(submenu: windowMenu)

        return menu
    }
}
