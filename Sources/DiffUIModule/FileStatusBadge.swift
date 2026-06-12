import SwiftUI

/// Compact colored letter marking a file's change status.
struct FileStatusBadge: View {
    let status: FileDiffStatus

    var body: some View {
        Text(letter)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(color, in: .rect(cornerRadius: 4))
    }

    private var letter: String {
        switch status {
        case .added: "A"
        case .deleted: "D"
        case .modified: "M"
        case .renamed: "R"
        }
    }

    private var color: Color {
        switch status {
        case .added: .green
        case .deleted: .red
        case .modified: .orange
        case .renamed: .blue
        }
    }
}
