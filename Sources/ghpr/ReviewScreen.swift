import DiffUIModule
import Foundation
import GithubModule
import SwiftUI

/// The review window: GitHub-style header bar, overview and changed files in
/// the sidebar, and a continuous scroll through every file's diff — the
/// sidebar selection follows the scroll position, and selecting a file
/// scrolls to it. Composes DiffUIModule components and maps GithubModule
/// models onto them; the two modules never meet directly.
struct ReviewScreen: View {
    private let model: ReviewModel
    private let highlighter = SyntaxHighlighter()

    @State private var tab: ReviewTab = .conversation
    @State private var selectedPath: String?
    @State private var viewedFiles: Set<String> = []
    @State private var collapsedFiles: Set<String> = []
    @State private var expandedFiles: [String: FileDiff] = [:]

    private let viewedStore = ViewedFilesStore()
    @State private var scrollTarget: DiffScrollTarget?
    @State private var composerTarget: DiffFileAnchor?
    @State private var isSubmitPopoverShown = false
    @State private var collapsedThreads: Set<String> = []

    init(model: ReviewModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            tabBar
            Divider()
            content
        }
        .alert("GitHub request failed", isPresented: errorShown) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            // Restore viewed marks whose file content is unchanged, and
            // start those files collapsed.
            let restored = await viewedStore.viewedPaths(in: pullRequestKey, matching: contentDigests)
            viewedFiles = restored
            collapsedFiles.formUnion(restored)
        }
    }

    private var pullRequestKey: String {
        "\(model.data.reference.repository.fullName)#\(model.data.reference.number)"
    }

    private var contentDigests: [String: String] {
        Dictionary(uniqueKeysWithValues: model.data.files.map { ($0.path, $0.contentDigest) })
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .conversation:
            ReviewOverviewView(data: model.data)
        case .commits:
            CommitsListView(commits: model.data.commits)
        case .checks:
            ChecksListView(checkRuns: model.data.checkRuns)
        case .files:
            filesSplitView
        }
    }

    /// Files with any full-context expansions swapped in.
    private var displayFiles: [FileDiff] {
        model.data.files.map { expandedFiles[$0.path] ?? $0 }
    }

    private var filesSplitView: some View {
        NavigationSplitView {
            FileListView(items: model.data.files.map(FileListItem.init), selectedPath: selectedPath) { item in
                selectedPath = item.path
                scrollTarget = DiffScrollTarget(path: item.path)
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            MultiFileDiffView(
                files: displayFiles,
                highlighter: highlighter,
                annotations: annotations,
                viewedFiles: viewedFiles,
                collapsedFiles: collapsedFiles,
                onViewedToggle: { path, isViewed in
                    if isViewed {
                        viewedFiles.insert(path)
                        collapsedFiles.insert(path)
                    } else {
                        viewedFiles.remove(path)
                        collapsedFiles.remove(path)
                    }
                    let digest = model.data.files.first { $0.path == path }?.contentDigest ?? ""
                    Task {
                        await viewedStore.setViewed(isViewed, path: path, digest: digest, in: pullRequestKey)
                    }
                },
                onCollapseToggle: { path in
                    if !collapsedFiles.insert(path).inserted {
                        collapsedFiles.remove(path)
                    }
                },
                onLineClick: { path, line in
                    composerTarget = line.anchors.first.map { DiffFileAnchor(path: path, anchor: $0) }
                },
                onExpandFile: { path in
                    Task {
                        if let expanded = await model.expandedFile(for: path) {
                            expandedFiles[path] = expanded
                        }
                    }
                },
                expandedFiles: Set(expandedFiles.keys),
                fileActions: fileActions,
                onVisibleFileChange: { selectedPath = $0 },
                scrollTarget: scrollTarget
            )
        }
    }

    /// "…" menu entries: open the file on GitHub at the head revision.
    private var fileActions: [DiffFileAction] {
        let repository = model.data.reference.repository.fullName
        let sha = model.data.pullRequest.head.sha
        let branch = model.data.pullRequest.head.ref
        return [
            DiffFileAction(title: "View file on GitHub") { path in
                open("https://github.com/\(repository)/blob/\(sha)/\(path)")
            },
            DiffFileAction(title: "Edit file on GitHub") { path in
                open("https://github.com/\(repository)/edit/\(branch)/\(path)")
            },
        ]
    }

    private var errorShown: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 4) {
            tabButton(.conversation, count: model.data.threads.count)
            tabButton(.commits, count: model.data.commits.count)
            tabButton(.checks, count: model.data.checkRuns.count)
            tabButton(.files, count: model.data.files.count)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func tabButton(_ target: ReviewTab, count: Int) -> some View {
        Button {
            tab = target
        } label: {
            HStack(spacing: 6) {
                Image(systemName: target.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(target.title)
                    .font(.callout.weight(tab == target ? .semibold : .regular))
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.quaternary.opacity(0.7), in: .capsule)
                }
            }
            .contentShape(.rect)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                tab == target ? AnyShapeStyle(.quaternary.opacity(0.55)) : AnyShapeStyle(.clear),
                in: .rect(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Header bar (title left, submit top-trailing, like GitHub)

    private var headerBar: some View {
        HStack(spacing: 12) {
            Text("\(model.data.pullRequest.title) ")
                .font(.headline)
            + Text("#\(model.data.pullRequest.number)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            if tab == .files {
                ViewedProgressView(viewed: viewedFiles.count, total: model.data.files.count)
            }
            submitButton
        }
        .lineLimit(1)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var submitButton: some View {
        Button {
            isSubmitPopoverShown = true
        } label: {
            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
            } else if model.pendingComments.isEmpty {
                Text("Submit review")
            } else {
                Text("Submit review (\(model.pendingComments.count))")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(model.isBusy)
        .popover(isPresented: $isSubmitPopoverShown, arrowEdge: .bottom) {
            SubmitReviewView(
                pendingCount: model.pendingComments.count,
                isBusy: model.isBusy,
                onSubmit: { event, body in
                    isSubmitPopoverShown = false
                    Task { await model.submitReview(event: event, body: body) }
                },
                onCancel: { isSubmitPopoverShown = false }
            )
        }
    }

    // MARK: Annotations

    /// Everything pinned under diff lines across all files: existing threads
    /// (with reply/resolve/react), pending batch comments, and the composer.
    private var annotations: [DiffFileAnchor: AnyView] {
        var sections: [DiffFileAnchor: [AnyView]] = [:]

        for thread in model.data.threads where thread.line != nil && !thread.isOutdated {
            let anchor = DiffFileAnchor(
                path: thread.path,
                anchor: thread.diffSide == "LEFT" ? .old(thread.line!) : .new(thread.line!)
            )
            sections[anchor, default: []].append(AnyView(
                ReviewThreadView(
                    thread: thread,
                    pullRequestAuthor: model.data.pullRequest.user?.login,
                    isCollapsed: collapsedThreads.contains(thread.id),
                    onToggleCollapse: {
                        if !collapsedThreads.insert(thread.id).inserted {
                            collapsedThreads.remove(thread.id)
                        }
                    },
                    onReply: { body in Task { await model.reply(to: thread, body: body) } },
                    onResolve: { Task { await model.resolve(thread: thread) } },
                    onReact: { comment, reaction in Task { await model.react(to: comment, with: reaction) } }
                )
            ))
        }

        for comment in model.pendingComments {
            sections[DiffFileAnchor(path: comment.path, anchor: comment.anchor), default: []].append(AnyView(
                PendingCommentView(comment: comment) {
                    model.removePendingComment(id: comment.id)
                }
            ))
        }

        if let composerTarget {
            sections[composerTarget, default: []].append(AnyView(
                CommentComposerView(
                    onAddToReview: { body in
                        model.addPendingComment(path: composerTarget.path, anchor: composerTarget.anchor, body: body)
                        self.composerTarget = nil
                    },
                    onCommentNow: { body in
                        self.composerTarget = nil
                        Task { await model.addSingleComment(path: composerTarget.path, anchor: composerTarget.anchor, body: body) }
                    },
                    onCancel: { self.composerTarget = nil }
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
                // Fill the hosted cell's width so cards pin to the leading
                // edge instead of centering.
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }
}
