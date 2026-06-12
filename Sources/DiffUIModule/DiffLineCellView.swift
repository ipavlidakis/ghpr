import AppKit
import Foundation

/// One recycled table cell: gutter numbers, change marker, and code, rendered
/// as a single attributed string so a row costs one text field. Hovering a
/// commentable line reveals GitHub's blue "+" button over the gutter.
final class DiffLineCellView: NSView {
    private let textField = NSTextField(labelWithString: "")
    private let addCommentButton = NSButton()

    /// Set for commentable rows; the "+" button only appears when non-nil.
    var onAddComment: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        textField.font = DiffStyle.codeFont
        textField.lineBreakMode = .byClipping
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        addCommentButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add comment")
        addCommentButton.isBordered = false
        addCommentButton.contentTintColor = .white
        addCommentButton.wantsLayer = true
        addCommentButton.layer?.backgroundColor = NSColor.systemBlue.cgColor
        addCommentButton.layer?.cornerRadius = 4
        addCommentButton.isHidden = true
        addCommentButton.target = self
        addCommentButton.action = #selector(addCommentClicked)
        addCommentButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addCommentButton)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            addCommentButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            addCommentButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            addCommentButton.widthAnchor.constraint(equalToConstant: 18),
            addCommentButton.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    /// Hover state is owned by the table's coordinator (one tracking area,
    /// one visible button) — per-cell tracking leaks stale buttons when
    /// exit events get lost during fast moves or scrolling.
    func setAddCommentVisible(_ visible: Bool) {
        addCommentButton.isHidden = !(visible && onAddComment != nil)
    }

    @objc private func addCommentClicked() {
        onAddComment?()
    }

    func configure(with row: DiffRow, gutterDigits: Int, tokens: [SyntaxToken]) {
        addCommentButton.isHidden = true
        switch row {
        case .hunkHeader(_, let header):
            textField.attributedStringValue = NSAttributedString(
                string: header,
                attributes: [.font: DiffStyle.codeFont, .foregroundColor: NSColor.secondaryLabelColor]
            )
        case .line(_, _, _, let line, let counterpart):
            textField.attributedStringValue = Self.lineText(line, counterpart: counterpart, gutterDigits: gutterDigits, tokens: tokens)
        case .fileHeader, .annotation:
            // These rows use their own cell types, never this one.
            textField.attributedStringValue = NSAttributedString()
        }
    }

    private static func lineText(_ line: DiffLine, counterpart: String?, gutterDigits: Int, tokens: [SyntaxToken]) -> NSAttributedString {
        let text = NSMutableAttributedString()

        let gutter = "\(padded(line.oldLineNumber, to: gutterDigits)) \(padded(line.newLineNumber, to: gutterDigits))"
        text.append(NSAttributedString(
            string: gutter,
            attributes: [.font: DiffStyle.codeFont, .foregroundColor: NSColor.tertiaryLabelColor]
        ))

        let (marker, markerColor): (String, NSColor) = switch line.kind {
        case .context: ("  ", .secondaryLabelColor)
        case .addition: (" +", .systemGreen)
        case .deletion: (" −", .systemRed)
        }
        text.append(NSAttributedString(
            string: "\(marker) ",
            attributes: [.font: DiffStyle.codeFont, .foregroundColor: markerColor]
        ))

        let code = NSMutableAttributedString(
            string: line.text,
            attributes: [.font: DiffStyle.codeFont, .foregroundColor: NSColor.labelColor]
        )
        let codeLength = line.text.utf16.count
        for token in tokens {
            guard let clamped = token.range.intersection(NSRange(location: 0, length: codeLength)) else { continue }
            code.addAttribute(.foregroundColor, value: DiffStyle.color(for: token.kind), range: clamped)
        }
        for range in emphasisRanges(for: line, counterpart: counterpart) {
            code.addAttribute(
                .backgroundColor,
                value: line.kind == .addition ? DiffStyle.additionEmphasis : DiffStyle.deletionEmphasis,
                range: NSRange(range, in: line.text)
            )
        }
        text.append(code)

        return text
    }

    /// Word-level emphasis, computed on demand for visible rows only.
    private static func emphasisRanges(for line: DiffLine, counterpart: String?) -> [Range<String.Index>] {
        guard let counterpart else { return [] }
        return switch line.kind {
        case .deletion: IntralineDiff.changedRanges(old: line.text, new: counterpart).old
        case .addition: IntralineDiff.changedRanges(old: counterpart, new: line.text).new
        case .context: []
        }
    }

    private static func padded(_ number: Int?, to width: Int) -> String {
        let text = number.map(String.init) ?? ""
        return String(repeating: " ", count: max(0, width - text.count)) + text
    }
}
