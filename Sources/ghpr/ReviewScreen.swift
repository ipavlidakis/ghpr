import DiffUIModule
import Foundation
import GithubModule
import SwiftUI

/// The review window: overview and changed files in the sidebar, the selected
/// content in the detail pane, and the pending-review bar at the bottom.
/// Composes DiffUIModule components and maps GithubModule models onto them —
/// the two modules never meet directly.
struct ReviewScreen: View {
    private let model: ReviewModel
    private let highlighter = SyntaxHighlighter()

    @State private var selectedPath: String?
    @State private var composerAnchor: DiffLineAnchor?
    @State private var isSubmitPopoverShown = false

    init(model: ReviewModel) {
        self.model = model
    }

    private var selectedFile: FileDiff? {
        model.data.files.first { $0.path == selectedPath }
    }

    var body: some View {
        @Bindable var model = model

        NavigationSplitView {
            VStack(spacing: 0) {
                overviewRow
                Divider()
                FileListView(items: model.data.files.map(FileListItem.init), selectedPath: selectedPath) {
                    selectedPath = $0.path
                    composerAnchor = nil
                }
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            if let selectedFile {
                FileDiffView(
                    fileDiff: selectedFile,
                    highlighter: highlighter,
                    annotations: annotations(for: selectedFile),
                    onLineClick: { line in
                        composerAnchor = line.anchors.first
                    }
                )
                .padding(12)
                .id(selectedFile.path)
            } else {
                ReviewOverviewView(data: model.data)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            reviewBar
        }
        .alert("GitHub request failed", isPresented: errorShown) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var errorShown: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    private var overviewRow: some View {
        Button {
            selectedPath = nil
            composerAnchor = nil
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

    // MARK: Bottom bar

    private var reviewBar: some View {
        HStack(spacing: 12) {
            if model.pendingComments.isEmpty {
                Text("No pending comments")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Label(
                    "\(model.pendingComments.count) pending comment\(model.pendingComments.count == 1 ? "" : "s")",
                    systemImage: "clock"
                )
                .font(.callout)
                .foregroundStyle(.orange)
            }
            Spacer()
            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
            Button("Submit review…") {
                isSubmitPopoverShown = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy)
            .popover(isPresented: $isSubmitPopoverShown, arrowEdge: .bottom) {
                SubmitReviewView(pendingCount: model.pendingComments.count, isBusy: model.isBusy) { event, body in
                    isSubmitPopoverShown = false
                    Task { await model.submitReview(event: event, body: body) }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: Annotations

    /// Everything pinned under this file's lines: existing threads (with
    /// reply/resolve), pending batch comments, and the active composer.
    private func annotations(for file: FileDiff) -> [DiffLineAnchor: AnyView] {
        var sections: [DiffLineAnchor: [AnyView]] = [:]

        let threads = model.data.threads.filter { $0.path == file.path && $0.line != nil && !$0.isOutdated }
        for thread in threads {
            let anchor: DiffLineAnchor = thread.diffSide == "LEFT" ? .old(thread.line!) : .new(thread.line!)
            sections[anchor, default: []].append(AnyView(
                ReviewThreadView(
                    thread: thread,
                    onReply: { body in Task { await model.reply(to: thread, body: body) } },
                    onResolve: { Task { await model.resolve(thread: thread) } }
                )
            ))
        }

        for comment in model.pendingComments where comment.path == file.path {
            sections[comment.anchor, default: []].append(AnyView(
                PendingCommentView(comment: comment) {
                    model.removePendingComment(id: comment.id)
                }
            ))
        }

        if let composerAnchor {
            sections[composerAnchor, default: []].append(AnyView(
                CommentComposerView(
                    onAddToReview: { body in
                        model.addPendingComment(path: file.path, anchor: composerAnchor, body: body)
                        self.composerAnchor = nil
                    },
                    onCommentNow: { body in
                        self.composerAnchor = nil
                        Task { await model.addSingleComment(path: file.path, anchor: composerAnchor, body: body) }
                    },
                    onCancel: { self.composerAnchor = nil }
                )
            ))
        }

        return sections.mapValues { views in
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(views.enumerated()), id: \.offset) { _, view in
                        view
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            )
        }
    }
}
