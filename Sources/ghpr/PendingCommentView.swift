import Foundation
import SwiftUI

/// One batched-but-unsubmitted comment, shown under its line.
struct PendingCommentView: View {
    let comment: PendingComment
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Pending", systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Remove from review")
            }
            Text(comment.body)
                .font(.callout)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.08), in: .rect(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.orange.opacity(0.4), lineWidth: 1)
        )
    }
}
