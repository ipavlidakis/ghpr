import Foundation
import SwiftUI

/// One file row of the changed-files list or tree.
struct FileListRowView: View {
    let item: FileListItem
    /// What to show as the file name (the last path component in tree mode,
    /// the full path in flat mode).
    var displayName: String?

    var body: some View {
        HStack(spacing: 6) {
            FileStatusBadge(status: item.status)
            Text(displayName ?? item.path)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            ChangeCountsLabel(additions: item.additions, deletions: item.deletions)
        }
    }
}
