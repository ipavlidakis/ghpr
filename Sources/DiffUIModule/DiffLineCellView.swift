import AppKit
import Foundation

/// One recycled table cell: gutter numbers, change marker, and code, rendered
/// as a single attributed string so a row costs one text field.
final class DiffLineCellView: NSView {
    private let textField = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        textField.font = DiffStyle.codeFont
        textField.lineBreakMode = .byClipping
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    func configure(with row: DiffRow, gutterDigits: Int) {
        switch row {
        case .hunkHeader(_, let header):
            textField.attributedStringValue = NSAttributedString(
                string: header,
                attributes: [.font: DiffStyle.codeFont, .foregroundColor: NSColor.secondaryLabelColor]
            )
        case .line(_, let line, let counterpart):
            textField.attributedStringValue = Self.lineText(line, counterpart: counterpart, gutterDigits: gutterDigits)
        }
    }

    private static func lineText(_ line: DiffLine, counterpart: String?, gutterDigits: Int) -> NSAttributedString {
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
