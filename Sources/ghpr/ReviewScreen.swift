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
            reviewTabs
        }
        .navigationTitle("\(model.data.reference.repository.fullName) #\(model.data.reference.number)")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                toolbarTitle
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItemGroup(placement: .primaryAction) {
                if tab == .conversation {
                    Button {
                        open(model.data.pullRequest.htmlUrl)
                    } label: {
                        Label("Open in GitHub", systemImage: "arrow.up.forward.square")
                    }
                    .buttonStyle(.glass)
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                }
                if tab == .files {
                    ViewedProgressView(viewed: viewedFiles.count, total: model.data.files.count)
                    submitButton
                }
            }
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

    private var reviewTabs: some View {
        TabView(selection: $tab) {
            ConversationView(model: model)
                .tabItem {
                    Label(ReviewTab.conversation.title, systemImage: ReviewTab.conversation.systemImage)
                }
                .badge(conversationCount)
                .tag(ReviewTab.conversation)
                .keyboardShortcut("1", modifiers: .command)

            CommitsListView(commits: model.data.commits)
                .tabItem {
                    Label(ReviewTab.commits.title, systemImage: ReviewTab.commits.systemImage)
                }
                .badge(model.data.commits.count)
                .tag(ReviewTab.commits)
                .keyboardShortcut("2", modifiers: .command)

            ChecksListView(checkRuns: model.data.checkRuns)
                .tabItem {
                    Label(ReviewTab.checks.title, systemImage: ReviewTab.checks.systemImage)
                }
                .badge(model.data.checkRuns.count)
                .tag(ReviewTab.checks)
                .keyboardShortcut("3", modifiers: .command)

            filesSplitView
                .tabItem {
                    Label(ReviewTab.files.title, systemImage: ReviewTab.files.systemImage)
                }
                .badge(model.data.files.count)
                .tag(ReviewTab.files)
                .keyboardShortcut("4", modifiers: .command)
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
        Group {
            if model.data.files.isEmpty {
                ContentUnavailableView(
                    "No changed files",
                    systemImage: "doc.text",
                    description: Text("This pull request did not return any file changes.")
                )
            } else {
                NavigationSplitView {
                    FileListView(items: model.data.files.map(FileListItem.init), selectedPath: selectedPath) { item in
                        selectedPath = item.path
                        scrollTarget = DiffScrollTarget(path: item.path)
                    }
                    .navigationSplitViewColumnWidth(min: 220, ideal: 280)
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

    /// Comment cards in the timeline, like GitHub's conversation counter.
    private var conversationCount: Int {
        model.data.timeline.count { if case .comment = $0 { true } else { false } }
    }

    private var toolbarTitle: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(model.data.pullRequest.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(verbatim: "\(model.data.reference.repository.fullName) #\(model.data.pullRequest.number)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: 360, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
        .buttonStyle(.glassProminent)
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
