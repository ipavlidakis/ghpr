import SwiftUI

/// One code line: two gutter numbers, the change marker, and the text.
struct DiffLineRowView: View {
    let line: DiffLine
    let emphasis: [Range<String.Index>]?
    let gutterWidth: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            gutterText(line.oldLineNumber)
            gutterText(line.newLineNumber)
            Text(marker)
                .font(DiffStyle.codeFont)
                .foregroundStyle(markerColor)
                .frame(width: 16)
            Text(text)
                .font(DiffStyle.codeFont)
                .textSelection(.enabled)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(background)
    }

    private func gutterText(_ number: Int?) -> some View {
        Text(number.map(String.init) ?? "")
            .font(DiffStyle.codeFont)
            .foregroundStyle(.tertiary)
            .frame(width: gutterWidth, alignment: .trailing)
            .padding(.trailing, 4)
    }

    private var text: AttributedString {
        if let emphasis, !emphasis.isEmpty {
            AttributedString(
                diffText: line.text,
                emphasis: emphasis,
                tint: line.kind == .addition ? DiffStyle.additionEmphasis : DiffStyle.deletionEmphasis
            )
        } else {
            AttributedString(line.text)
        }
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
