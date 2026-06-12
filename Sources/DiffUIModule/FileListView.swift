import Foundation
import SwiftUI

/// The changed-files list with native full-row selection. Selection flows out
/// through `onSelect` only; the highlighted row flows back in via `selectedPath`.
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
        List(items, selection: selection) { item in
            FileListRowView(item: item)
        }
        .listStyle(.sidebar)
    }

    /// Bridges `List` selection to the one-directional callback: writes never
    /// mutate local state, they surface through `onSelect` and come back as
    /// a new `selectedPath`. Deselection (cmd-click) is ignored.
    private var selection: Binding<String?> {
        Binding(
            get: { selectedPath },
            set: { newValue in
                guard let item = items.first(where: { $0.path == newValue }) else { return }
                onSelect(item)
            }
        )
    }
}
