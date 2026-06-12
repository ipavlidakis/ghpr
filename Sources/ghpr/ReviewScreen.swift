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
    @State private var imageDiffs: [String: ImageDiffSides] = [:]

    private let viewedStore = ViewedFilesStore()
    @State private var scrollTarget: DiffScrollTarget?
    @State private var composerTarget: DiffFileAnchor?
    @State private var isSubmitPopoverShown = false
    /// Threads whose collapse state the user inverted from the default
    /// (resolved → collapsed). Keyed this way, a thread resolved mid-session
    /// auto-collapses after the reload, and manual choices survive reloads.
    @State private var toggledThreads: Set<String> = []

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
        .task(id: model.data.pullRequest.head.sha) {
            // Fetch both versions of every changed image for 2-up previews.
            for file in model.data.files where file.isBinary && ImageDiffView.supports(file.path) {
                if Task.isCancelled { return }
                if imageDiffs[file.path] == nil {
                    imageDiffs[file.path] = await model.imageDiff(for: file)
                }
            }
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
            ConversationView(model: model)
        case .commits:
            CommitsListView(commits: model.data.commits)
        case .checks:
            ChecksListView(checkRuns: model.data.checkRuns)
        case .files:
            filesSplitView
        }
    }

    /// Files in tree traversal order (matching the sidebar), with any
    /// full-context expansions swapped in.
    private var displayFiles: [FileDiff] {
        let order = FileTreeNode.orderedPaths(from: model.data.files.map(FileListItem.init))
        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
        return model.data.files
            .sorted { (rank[$0.path] ?? .max) < (rank[$1.path] ?? .max) }
            .map { expandedFiles[$0.path] ?? $0 }
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
                filePreviews: filePreviews,
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

    /// 2-up image comparisons keyed by path, versioned by their bytes so
    /// the table re-measures when a fetch completes.
    private var filePreviews: [String: DiffAnnotation] {
        imageDiffs.reduce(into: [:]) { result, entry in
            var hasher = Hasher()
            hasher.combine(entry.value.old?.count ?? -1)
            hasher.combine(entry.value.new?.count ?? -1)
            result[entry.key] = DiffAnnotation(
                version: hasher.finalize(),
                content: AnyView(ImageDiffView(sides: entry.value))
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
            tabButton(.conversation, count: conversationCount)
            tabButton(.commits, count: model.data.commits.count)
            tabButton(.checks, count: model.data.checkRuns.count)
            tabButton(.files, count: model.data.files.count)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
    }

    /// Comment cards in the timeline, like GitHub's conversation counter.
    private var conversationCount: Int {
        model.data.timeline.count { if case .comment = $0 { true } else { false } }
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
            // Invisible rather than removed off the files tab: the button
            // defines the header's height, so removing it makes the whole
            // bar jump between tabs.
            ViewedProgressView(viewed: viewedFiles.count, total: model.data.files.count)
                .opacity(tab == .files ? 1 : 0)
            submitButton
                .opacity(tab == .files ? 1 : 0)
                .disabled(tab != .files)
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
        .keyboardShortcut(.return, modifiers: .command)
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
    /// Each anchor carries a version derived from whatever affects its
    /// rendering, so the diff table knows when to re-measure.
    private var annotations: [DiffFileAnchor: DiffAnnotation] {
        var sections: [DiffFileAnchor: [AnyView]] = [:]
        var versions: [DiffFileAnchor: [String]] = [:]

        for thread in model.data.threads where thread.line != nil && !thread.isOutdated {
            let anchor = DiffFileAnchor(
                path: thread.path,
                anchor: thread.diffSide == "LEFT" ? .old(thread.line!) : .new(thread.line!)
            )
            let isCollapsed = thread.isResolved != toggledThreads.contains(thread.id)
            sections[anchor, default: []].append(AnyView(
                ReviewThreadView(
                    thread: thread,
                    pullRequestAuthor: model.data.pullRequest.user?.login,
                    isCollapsed: isCollapsed,
                    onToggleCollapse: {
                        if !toggledThreads.insert(thread.id).inserted {
                            toggledThreads.remove(thread.id)
                        }
                    },
                    onReply: { body in Task { await model.reply(to: thread, body: body) } },
                    onResolve: { Task { await model.resolve(thread: thread) } },
                    onReact: { comment, reaction in Task { await model.react(to: comment, with: reaction) } }
                )
            ))
            let reactionCount = thread.comments.reduce(0) { $0 + $1.reactions.reduce(0) { $0 + $1.count } }
            versions[anchor, default: []].append(
                "thread:\(thread.id):\(thread.isResolved):\(isCollapsed):\(thread.comments.count):\(reactionCount)"
            )
        }

        for comment in model.pendingComments {
            let anchor = DiffFileAnchor(path: comment.path, anchor: comment.anchor)
            sections[anchor, default: []].append(AnyView(
                PendingCommentView(comment: comment) {
                    model.removePendingComment(id: comment.id)
                }
            ))
            versions[anchor, default: []].append("pending:\(comment.id)")
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
            versions[composerTarget, default: []].append("composer")
        }

        return sections.reduce(into: [:]) { result, entry in
            var hasher = Hasher()
            hasher.combine(versions[entry.key] ?? [])
            result[entry.key] = DiffAnnotation(
                version: hasher.finalize(),
                content: AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(entry.value.enumerated()), id: \.offset) { _, view in
                            view
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    // Fill the hosted cell's width so cards pin to the
                    // leading edge instead of centering.
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
            )
        }
    }
}
