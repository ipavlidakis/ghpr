import AppKit
import Foundation

final class FileListCellView: NSTableCellView {
    private let stack = NSStackView()
    private let iconView = NSImageView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    func configure(with node: FileTreeNode) {
        if let item = node.item {
            iconView.isHidden = true
            statusLabel.isHidden = false
            configureStatus(item.status)
            titleLabel.stringValue = node.name
            titleLabel.toolTip = item.path
            setAccessibilityLabel("File \(item.path)")
            setAccessibilityValue("\(item.status.accessibilityDescription), \(item.additions) additions, \(item.deletions) deletions")
        } else {
            iconView.isHidden = false
            statusLabel.isHidden = true
            titleLabel.stringValue = node.name
            titleLabel.toolTip = node.name
            setAccessibilityLabel("Folder \(node.name)")
            setAccessibilityValue("Expanded")
        }
        setAccessibilityIdentifier("ghpr.files.sidebar.row")
    }

    private func setup() {
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        iconView.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        iconView.contentTintColor = .secondaryLabelColor

        statusLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.alignment = .center
        statusLabel.wantsLayer = true
        statusLabel.layer?.cornerRadius = 4

        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.maximumNumberOfLines = 1
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            statusLabel.widthAnchor.constraint(equalToConstant: 16),
            statusLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func configureStatus(_ status: FileDiffStatus) {
        statusLabel.stringValue = switch status {
        case .added: "A"
        case .deleted: "D"
        case .modified: "M"
        case .renamed: "R"
        }
        statusLabel.layer?.backgroundColor = switch status {
        case .added: NSColor.systemGreen.cgColor
        case .deleted: NSColor.systemRed.cgColor
        case .modified: NSColor.systemOrange.cgColor
        case .renamed: NSColor.systemBlue.cgColor
        }
    }
}
