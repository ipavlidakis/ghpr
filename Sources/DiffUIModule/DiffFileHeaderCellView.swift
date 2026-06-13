import AppKit
import Foundation
import SwiftUI

/// Native table cell shell for a SwiftUI file header row.
final class DiffFileHeaderCellView: NSView {
    private var hostingView: NSHostingView<AnyView>?
    private var filePath = ""

    /// Called with the new checked state when the user toggles "Viewed".
    var onViewedToggle: ((Bool) -> Void)?
    /// Called when the collapse affordance is clicked.
    var onCollapseToggle: (() -> Void)?
    /// Expand-all-lines (full file context); the button only shows when set.
    var onExpand: (() -> Void)?
    /// Entries of the "…" menu.
    var fileActions: [DiffFileAction] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    func configure(with file: FileDiff, isCollapsed: Bool, isViewed: Bool) {
        filePath = file.path
        setAccessibilityIdentifier("ghpr.files.header.row")
        setAccessibilityLabel("File \(file.path)")
        setAccessibilityValue("\(file.status.accessibilityDescription), \(file.additions) additions, \(file.deletions) deletions")
        let content = DiffFileHeaderRowView(
            file: file,
            isCollapsed: isCollapsed,
            isViewed: isViewed,
            isExpandable: onExpand != nil,
            hasActions: !fileActions.isEmpty,
            onCollapse: { [weak self] in self?.onCollapseToggle?() },
            onViewedToggle: { [weak self] isViewed in self?.onViewedToggle?(isViewed) },
            onCopy: { [weak self] in self?.copyPath() },
            onExpand: { [weak self] in self?.onExpand?() },
            onMore: { [weak self] in self?.showActionsMenu() }
        )

        if let hostingView {
            hostingView.rootView = AnyView(content)
        } else {
            let hostingView = NSHostingView(rootView: AnyView(content))
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(hostingView)
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            self.hostingView = hostingView
        }
    }

    private func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(filePath, forType: .string)
    }

    private func showActionsMenu() {
        guard !fileActions.isEmpty else { return }
        let menu = NSMenu()
        for action in fileActions {
            let item = NSMenuItem(title: action.title, action: #selector(menuItemSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = action
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: NSPoint(x: bounds.maxX - 44, y: bounds.midY + 8), in: self)
    }

    @objc private func menuItemSelected(_ item: NSMenuItem) {
        guard let action = item.representedObject as? DiffFileAction else { return }
        action.handler(filePath)
    }
}
