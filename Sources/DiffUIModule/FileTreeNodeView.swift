import Foundation
import SwiftUI

/// One row of the file tree: a disclosure group for directories (expanded
/// by default), a selectable row for files.
struct FileTreeNodeView: View {
    let node: FileTreeNode

    @State private var isExpanded = true

    var body: some View {
        if let children = node.children {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(children) { child in
                    FileTreeNodeView(node: child)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    Text(node.name)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .selectionDisabled()
        } else if let item = node.item {
            FileListRowView(item: item, displayName: node.name)
                .tag(item.path)
        }
    }
}
