import AppKit
import Foundation

/// Native table cell for a file's header row in the multi-file table:
/// collapse chevron, status letter, path, change counts, and the
/// GitHub-style "Viewed" checkbox that collapses the file when checked.
final class DiffFileHeaderCellView: NSView {
    private let textField = NSTextField(labelWithString: "")
    private let copyButton = NSButton()
    private let expandButton = NSButton()
    private let menuButton = NSButton()
    private let viewedCheckbox = NSButton(checkboxWithTitle: "Viewed", target: nil, action: nil)

    private var filePath = ""

    /// Called with the new checked state when the user toggles "Viewed".
    var onViewedToggle: ((Bool) -> Void)?
    /// Expand-all-lines (full file context); the button only shows when set.
    var onExpand: (() -> Void)?
    /// Entries of the "…" menu.
    var fileActions: [DiffFileAction] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
        // Single line via maximumNumberOfLines, not usesSingleLineMode —
        // the latter silently replaces middle truncation with tail clipping.
        textField.lineBreakMode = .byTruncatingMiddle
        textField.maximumNumberOfLines = 1
        // Truncate the path rather than pushing the trailing controls out.
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        configureIconButton(copyButton, symbol: "doc.on.doc", help: "Copy file name", action: #selector(copyPath))
        configureIconButton(expandButton, symbol: "rectangle.expand.vertical", help: "Expand all lines", action: #selector(expandTapped))
        configureIconButton(menuButton, symbol: "ellipsis", help: "More actions", action: #selector(menuTapped(_:)))

        viewedCheckbox.font = NSFont.systemFont(ofSize: 11)
        viewedCheckbox.controlSize = .small
        viewedCheckbox.target = self
        viewedCheckbox.action = #selector(viewedToggled(_:))
        viewedCheckbox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(viewedCheckbox)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            copyButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            copyButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            expandButton.leadingAnchor.constraint(equalTo: copyButton.trailingAnchor, constant: 6),
            expandButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            viewedCheckbox.leadingAnchor.constraint(greaterThanOrEqualTo: expandButton.trailingAnchor, constant: 12),
            // Clear of the overlay scroller at the table's trailing edge.
            menuButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            menuButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            viewedCheckbox.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -10),
            viewedCheckbox.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    private func configureIconButton(_ button: NSButton, symbol: String, help: String, action: Selector) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: help)
        button.isBordered = false
        button.contentTintColor = .secondaryLabelColor
        button.toolTip = help
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
    }

    @objc private func viewedToggled(_ sender: NSButton) {
        onViewedToggle?(sender.state == .on)
    }

    @objc private func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(filePath, forType: .string)
    }

    @objc private func expandTapped() {
        onExpand?()
    }

    @objc private func menuTapped(_ sender: NSButton) {
        guard !fileActions.isEmpty else { return }
        let menu = NSMenu()
        for action in fileActions {
            let item = NSMenuItem(title: action.title, action: #selector(menuItemSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = action
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY + 4), in: sender)
    }

    @objc private func menuItemSelected(_ item: NSMenuItem) {
        guard let action = item.representedObject as? DiffFileAction else { return }
        action.handler(filePath)
    }

    func configure(with file: FileDiff, isCollapsed: Bool, isViewed: Bool) {
        filePath = file.path
        viewedCheckbox.state = isViewed ? .on : .off
        expandButton.isHidden = onExpand == nil
        menuButton.isHidden = fileActions.isEmpty

        let text = NSMutableAttributedString()

        text.append(NSAttributedString(
            string: isCollapsed ? "▸  " : "▾  ",
            attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: NSColor.secondaryLabelColor]
        ))
        text.append(NSAttributedString(
            string: "\(statusLetter(for: file.status)) ",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: statusColor(for: file.status)]
        ))
        text.append(NSAttributedString(
            string: title(for: file),
            attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.labelColor]
        ))
        if file.additions > 0 {
            text.append(NSAttributedString(
                string: "  +\(file.additions)",
                attributes: [.font: DiffStyle.codeFont, .foregroundColor: NSColor.systemGreen]
            ))
        }
        if file.deletions > 0 {
            text.append(NSAttributedString(
                string: "  −\(file.deletions)",
                attributes: [.font: DiffStyle.codeFont, .foregroundColor: NSColor.systemRed]
            ))
        }

        textField.attributedStringValue = text
    }

    private func title(for file: FileDiff) -> String {
        if case .renamed(let from) = file.status {
            "\(from) → \(file.path)"
        } else {
            file.path
        }
    }

    private func statusLetter(for status: FileDiffStatus) -> String {
        switch status {
        case .added: "A"
        case .deleted: "D"
        case .modified: "M"
        case .renamed: "R"
        }
    }

    private func statusColor(for status: FileDiffStatus) -> NSColor {
        switch status {
        case .added: .systemGreen
        case .deleted: .systemRed
        case .modified: .systemOrange
        case .renamed: .systemBlue
        }
    }
}
