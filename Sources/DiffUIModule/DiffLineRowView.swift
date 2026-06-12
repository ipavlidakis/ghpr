import Foundation
import SwiftUI

/// One code line: two gutter numbers, the change marker, and the text.
///
/// Intra-line emphasis is computed here, on demand for visible rows only —
/// one word-level diff per paired line is microseconds, while running all of
/// them at file-open time froze large files.
struct DiffLineRowView: View {
    let line: DiffLine
    let counterpart: String?
    let gutterWidth: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            gutterText(line.oldLineNumber)
            gutterText(line.newLineNumber)
            Text(marker)
                .font(DiffStyle.codeFont)
                .foregroundStyle(markerColor)
                .frame(width: 16)
            text
                .font(DiffStyle.codeFont)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 18)
        .background(background)
    }

    private func gutterText(_ number: Int?) -> some View {
        Text(number.map(String.init) ?? "")
            .font(DiffStyle.codeFont)
            .foregroundStyle(.tertiary)
            .frame(width: gutterWidth, alignment: .trailing)
            .padding(.trailing, 4)
    }

    private var text: Text {
        guard let counterpart else { return Text(verbatim: line.text) }

        let ranges = switch line.kind {
        case .deletion:
            IntralineDiff.changedRanges(old: line.text, new: counterpart).old
        case .addition:
            IntralineDiff.changedRanges(old: counterpart, new: line.text).new
        case .context:
            [Range<String.Index>]()
        }
        guard !ranges.isEmpty else { return Text(verbatim: line.text) }

        let tint = line.kind == .addition ? DiffStyle.additionEmphasis : DiffStyle.deletionEmphasis
        return Text(AttributedString(diffText: line.text, emphasis: ranges, tint: tint))
    }

    private var marker: String {
        switch line.kind {
        case .context: " "
        case .addition: "+"
        case .deletion: "−"
        }
    }

    private var markerColor: Color {
        switch line.kind {
        case .context: .secondary
        case .addition: .green
        case .deletion: .red
        }
    }

    private var background: Color {
        switch line.kind {
        case .context: .clear
        case .addition: DiffStyle.additionBackground
        case .deletion: DiffStyle.deletionBackground
        }
    }
}
