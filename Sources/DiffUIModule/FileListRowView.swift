import SwiftUI

/// One row of the changed-files list.
struct FileListRowView: View {
    let item: FileListItem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                FileStatusBadge(status: item.status)
                Text(item.path)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 4)
                ChangeCountsLabel(additions: item.additions, deletions: item.deletions)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.2) : nil)
    }
}
