import Foundation
import SwiftUI

/// The `+N −M` change counters shown next to a file.
///
/// On prominent backgrounds (a selected sidebar row) the fixed green/red
/// would vanish into the accent color, so the counters fall back to the
/// inherited foreground (white on selection).
struct ChangeCountsLabel: View {
    let additions: Int
    let deletions: Int

    @Environment(\.backgroundProminence) private var backgroundProminence

    var body: some View {
        HStack(spacing: 6) {
            if additions > 0 {
                Text("+\(additions)")
                    .foregroundStyle(style(for: .green))
            }
            if deletions > 0 {
                Text("−\(deletions)")
                    .foregroundStyle(style(for: .red))
            }
        }
        .font(.caption.monospacedDigit())
    }

    private func style(for color: Color) -> AnyShapeStyle {
        backgroundProminence == .increased ? AnyShapeStyle(.primary) : AnyShapeStyle(color)
    }
}
