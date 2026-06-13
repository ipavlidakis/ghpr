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
    static func run(title: String, size: NSSize = NSSize(width: 1440, height: 920), content: some View) {
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
    static func openWindow(title: String, size: NSSize = NSSize(width: 1440, height: 920), content: some View) {
        let hostingController = NSHostingController(rootView: content)
        hostingController.sizingOptions = []

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier("ghpr.window")
        window.isReleasedWhenClosed = false
        window.contentViewController = hostingController
        window.minSize = NSSize(width: min(size.width, 960), height: min(size.height, 600))
        window.makeKeyAndOrderFront(nil)

        let frame = centeredFrame(size: size).offsetBy(dx: cascadeOffset, dy: -cascadeOffset)
        cascadeOffset = (cascadeOffset + 26).truncatingRemainder(dividingBy: 130)
        window.setFrame(frame, display: true)
        frameGuard.protect(window, frame: frame)
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
        let app = NSApplication.shared
        let appName = ProcessInfo.processInfo.processName

        let appMenu = NSMenu(title: appName)
        appMenu.addItem(withTitle: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let servicesMenu = NSMenu(title: "Services")
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        app.servicesMenu = servicesMenu
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(submenu: appMenu)

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: "\u{8}")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(submenu: editMenu)

        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        app.windowsMenu = windowMenu
        menu.addItem(submenu: windowMenu)

        return menu
    }
}
