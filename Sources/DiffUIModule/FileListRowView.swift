import Foundation
import SwiftUI

/// One row of the changed-files list.
struct FileListRowView: View {
    let item: FileListItem

    var body: some View {
        HStack(spacing: 6) {
            FileStatusBadge(status: item.status)
            Text(item.path)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            ChangeCountsLabel(additions: item.additions, deletions: item.deletions)
        }
    }
}
