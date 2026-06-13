import AppKit
import Foundation

/// Native placeholder cell for large diffs. Avoids a SwiftUI hosting view for
/// every skipped file while preserving the same visual layout.
final class LargeDiffPlaceholderCellView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier("largeDiffPlaceholderCell")

    var onLoad: (() -> Void)?

    private let skeletonStack = NSStackView()
    private let messageStack = NSStackView()
    private let loadButton = NSButton()
    private let subtitleLabel = NSTextField(labelWithString: "Large diffs are not rendered by default.")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    func configure(with file: FileDiff) {
        setAccessibilityIdentifier("ghpr.files.large-diff")
        setAccessibilityLabel("Large diff placeholder for \(file.path)")
        loadButton.setAccessibilityIdentifier("ghpr.files.load-diff")
        loadButton.setAccessibilityLabel("Load diff for \(file.path)")
        loadButton.setAccessibilityHelp("Renders this large file diff")
    }

    private func setup() {
        wantsLayer = true

        let contentStack = NSStackView()
        contentStack.orientation = .horizontal
        contentStack.alignment = .centerY
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        skeletonStack.orientation = .vertical
        skeletonStack.alignment = .leading
        skeletonStack.spacing = 10
        skeletonStack.translatesAutoresizingMaskIntoConstraints = false
        skeletonStack.setContentHuggingPriority(.required, for: .horizontal)
        addSkeletonRows()

        messageStack.orientation = .vertical
        messageStack.alignment = .centerX
        messageStack.spacing = 6
        messageStack.translatesAutoresizingMaskIntoConstraints = false

        loadButton.title = "Load Diff"
        loadButton.target = self
        loadButton.action = #selector(loadDiff)
        loadButton.isBordered = false
        loadButton.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        loadButton.contentTintColor = .controlAccentColor

        subtitleLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        subtitleLabel.textColor = .secondaryLabelColor

        messageStack.addArrangedSubview(loadButton)
        messageStack.addArrangedSubview(subtitleLabel)

        contentStack.addArrangedSubview(skeletonStack)
        contentStack.addArrangedSubview(messageStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -28),
            skeletonStack.widthAnchor.constraint(equalToConstant: 260),
            messageStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 220)
        ])
    }

    private func addSkeletonRows() {
        skeletonStack.addArrangedSubview(skeletonBar(width: 70))
        skeletonStack.addArrangedSubview(skeletonRow(widths: [90, 160]))
        skeletonStack.addArrangedSubview(skeletonRow(widths: [120, 64, 74]))
        skeletonStack.addArrangedSubview(skeletonBar(width: 48))
    }

    private func skeletonRow(widths: [CGFloat]) -> NSStackView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        for width in widths {
            row.addArrangedSubview(skeletonBar(width: width))
        }
        return row
    }

    private func skeletonBar(width: CGFloat) -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.cornerRadius = 3
        view.layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.35).cgColor
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: width),
            view.heightAnchor.constraint(equalToConstant: 9)
        ])
        return view
    }

    @objc private func loadDiff() {
        onLoad?()
    }
}
