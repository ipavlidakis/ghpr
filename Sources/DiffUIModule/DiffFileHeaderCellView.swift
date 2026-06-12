import AppKit
import Foundation

/// Native table cell for a file's header row in the multi-file table:
/// collapse chevron, status letter, path, and change counts.
final class DiffFileHeaderCellView: NSView {
    private let textField = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        textField.lineBreakMode = .byTruncatingMiddle
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    func configure(with file: FileDiff, isCollapsed: Bool) {
        let text = NSMutableAttributedString()

        text.append(NSAttributedString(
            string: isCollapsed ? "▸ " : "▾ ",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
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
