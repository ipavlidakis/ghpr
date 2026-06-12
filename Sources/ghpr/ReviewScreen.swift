import DiffUIModule
import Foundation
import GithubModule
import SwiftUI

/// The review window: overview and changed files in the sidebar, the selected
/// content in the detail pane. Composes DiffUIModule components and maps
/// GithubModule models onto them — the two modules never meet directly.
struct ReviewScreen: View {
    private let data: ReviewData
    private let items: [FileListItem]
    private let highlighter = SyntaxHighlighter()

    @State private var selectedPath: String?

    init(data: ReviewData) {
        self.data = data
        items = data.files.map(FileListItem.init)
    }

    private var selectedFile: FileDiff? {
        data.files.first { $0.path == selectedPath }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                overviewRow
                Divider()
                FileListView(items: items, selectedPath: selectedPath) {
                    selectedPath = $0.path
                }
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            if let selectedFile {
                FileDiffView(
                    fileDiff: selectedFile,
                    highlighter: highlighter,
                    annotations: annotations(for: selectedFile)
                )
                .padding(12)
                .id(selectedFile.path)
            } else {
                ReviewOverviewView(data: data)
            }
        }
    }

    private var overviewRow: some View {
        Button {
            selectedPath = nil
        } label: {
            Label("Overview", systemImage: "list.bullet.rectangle")
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(selectedPath == nil ? Color.accentColor.opacity(0.15) : .clear)
    }

    /// This file's inline threads, grouped per anchored line. Outdated
    /// threads have no line in the current diff and stay overview-only.
    private func annotations(for file: FileDiff) -> [DiffLineAnchor: AnyView] {
        let threads = data.threads.filter { $0.path == file.path && $0.line != nil && !$0.isOutdated }
        let grouped = Dictionary(grouping: threads) { thread in
            thread.diffSide == "LEFT" ? DiffLineAnchor.old(thread.line!) : DiffLineAnchor.new(thread.line!)
        }
        return grouped.mapValues { threads in
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(threads, id: \.id) { thread in
                        ReviewThreadView(thread: thread)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            )
        }
    }
}
