import Foundation
import SwiftUI

/// File path, status badge, change counts, and the collapse toggle.
struct FileDiffHeaderView: View {
    let fileDiff: FileDiff
    @Binding var isCollapsed: Bool

    var body: some View {
        Button {
            isCollapsed.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                FileStatusBadge(status: fileDiff.status)
                Text(title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                ChangeCountsLabel(additions: fileDiff.additions, deletions: fileDiff.deletions)
            }
            .contentShape(.rect)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(.quaternary.opacity(0.5))
    }

    private var title: String {
        if case .renamed(let from) = fileDiff.status {
            "\(from) → \(fileDiff.path)"
        } else {
            fileDiff.path
        }
    }
}
