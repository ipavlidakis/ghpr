import SwiftUI

/// The changed-files list. Selection flows out through `onSelect` only;
/// the highlighted row flows back in via `selectedPath`.
package struct FileListView: View {
    private let items: [FileListItem]
    private let selectedPath: String?
    private let onSelect: (FileListItem) -> Void

    package init(items: [FileListItem], selectedPath: String?, onSelect: @escaping (FileListItem) -> Void) {
        self.items = items
        self.selectedPath = selectedPath
        self.onSelect = onSelect
    }

    package var body: some View {
        List(items) { item in
            FileListRowView(item: item, isSelected: item.path == selectedPath) {
                onSelect(item)
            }
        }
        .listStyle(.sidebar)
    }
}
