import DiffUIModule
import Foundation
import SwiftUI

/// Demo composition of the two DiffUIModule components: changed-files
/// sidebar plus the selected file's diff.
struct DemoScreen: View {
    private let files: [FileDiff]
    private let items: [FileListItem]
    private let highlighter = SyntaxHighlighter()

    @State private var selectedPath: String?

    init(files: [FileDiff]) {
        self.files = files
        items = files.map(FileListItem.init)
    }

    private var selectedFile: FileDiff? {
        files.first { $0.path == selectedPath } ?? files.first
    }

    var body: some View {
        NavigationSplitView {
            FileListView(items: items, selectedPath: selectedFile?.path) {
                selectedPath = $0.path
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 320)
        } detail: {
            if let selectedFile {
                FileDiffView(fileDiff: selectedFile, highlighter: highlighter)
                    .padding(12)
                    .id(selectedFile.path)
            } else {
                ContentUnavailableView("No changed files", systemImage: "doc.text")
            }
        }
    }
}
