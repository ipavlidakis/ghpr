import SwiftUI

/// A single row of the diff body: a hunk header or a code line with
/// its annotation slot.
struct DiffRowView<Annotation: View>: View {
    let row: DiffRow
    let gutterWidth: CGFloat
    let annotation: (DiffLine) -> Annotation?

    var body: some View {
        switch row {
        case .hunkHeader(_, let header):
            Text(header)
                .font(DiffStyle.codeFont)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.3))
        case .line(_, let line, let emphasis):
            VStack(alignment: .leading, spacing: 0) {
                DiffLineRowView(line: line, emphasis: emphasis, gutterWidth: gutterWidth)
                if let annotationView = annotation(line) {
                    annotationView
                        .padding(.leading, gutterWidth * 2 + 16)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}
